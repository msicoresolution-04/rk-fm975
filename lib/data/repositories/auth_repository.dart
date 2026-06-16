import 'package:uuid/uuid.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/services/crypto_service.dart';
import 'package:rkfm_broadcast/core/native/native_bridge.dart';
import 'package:rkfm_broadcast/data/database/app_database.dart';
import 'package:rkfm_broadcast/data/models/user_models.dart';

class AuthRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  AuthRepository(this._db);

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await _db.database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await _db.database;
    final results = await db.query('users', orderBy: 'username ASC');
    return results.map(UserModel.fromMap).toList();
  }

  Future<AuthResult> login(String username, String password) async {
    final deviceId = await NativeBridge.getDeviceId();
    final user = await getUserByUsername(username);

    if (user == null) {
      await _recordLoginHistory('', username, deviceId, false, 'User not found');
      return AuthResult.failure('Invalid username or password');
    }

    if (!user.isActive) {
      await _recordLoginHistory(user.id, username, deviceId, false, 'Account disabled');
      return AuthResult.failure('Account is disabled');
    }

    if (user.lockedUntil != null && user.lockedUntil!.isAfter(DateTime.now())) {
      await _recordLoginHistory(user.id, username, deviceId, false, 'Account locked');
      return AuthResult.failure('Account locked. Try again later.');
    }

    final hash = CryptoService.hashPassword(password, user.salt);
    if (hash != user.passwordHash) {
      final attempts = user.failedLoginAttempts + 1;
      DateTime? lockedUntil;
      if (attempts >= AppConstants.maxLoginAttempts) {
        lockedUntil = DateTime.now().add(const Duration(minutes: AppConstants.lockoutMinutes));
      }
      await _updateUser(user.copyWith(
        failedLoginAttempts: attempts,
        lockedUntil: lockedUntil,
      ));
      await _recordLoginHistory(user.id, username, deviceId, false, 'Invalid password');
      return AuthResult.failure('Invalid username or password');
    }

    final updatedUser = user.copyWith(
      failedLoginAttempts: 0,
      lockedUntil: null,
      lastLoginAt: DateTime.now(),
    );
    await _updateUser(updatedUser);

    final session = await _createSession(user.id, deviceId);
    await _recordLoginHistory(user.id, username, deviceId, true, null);

    return AuthResult.success(updatedUser, session);
  }

  Future<void> logout(String sessionId) async {
    final db = await _db.database;
    await db.update('sessions', {'is_active': 0}, where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<SessionModel?> getActiveSession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'sessions',
      where: 'id = ? AND is_active = 1',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    final session = SessionModel.fromMap(results.first);
    if (session.expiresAt.isBefore(DateTime.now())) {
      await logout(sessionId);
      return null;
    }
    return session;
  }

  Future<bool> changePassword(String userId, String newPassword) async {
    final user = await getUserById(userId);
    if (user == null) return false;
    final salt = CryptoService.generateSalt();
    final hash = CryptoService.hashPassword(newPassword, salt);
    await _updateUser(user.copyWith(
      passwordHash: hash,
      salt: salt,
      mustChangePassword: false,
    ));
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final db = await _db.database;
    final results = await db.query('app_settings', limit: 1);
    if (results.isEmpty) return pin == AppConstants.defaultPin;
    return results.first['pin'] == pin;
  }

  Future<void> updateUser(UserModel user) async {
    await _updateUser(user);
  }

  Future<UserModel> createUser({
    required String username,
    required String password,
    required UserRole role,
    required String displayName,
    bool mustChangePassword = true,
  }) async {
    final salt = CryptoService.generateSalt();
    final hash = CryptoService.hashPassword(password, salt);
    final user = UserModel(
      id: _uuid.v4(),
      username: username.toLowerCase(),
      passwordHash: hash,
      salt: salt,
      role: role,
      displayName: displayName,
      mustChangePassword: mustChangePassword,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('users', user.toMap());
    return user;
  }

  Future<void> _updateUser(UserModel user) async {
    final db = await _db.database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<SessionModel> _createSession(String userId, String deviceId) async {
    final now = DateTime.now();
    final session = SessionModel(
      id: _uuid.v4(),
      userId: userId,
      deviceId: deviceId,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: AppConstants.sessionTimeoutMinutes)),
    );
    final db = await _db.database;
    await db.insert('sessions', session.toMap());
    return session;
  }

  Future<void> _recordLoginHistory(
    String userId,
    String username,
    String deviceId,
    bool success,
    String? failureReason,
  ) async {
    final db = await _db.database;
    await db.insert('login_history', LoginHistoryModel(
      id: _uuid.v4(),
      userId: userId,
      username: username,
      deviceId: deviceId,
      success: success,
      failureReason: failureReason,
      timestamp: DateTime.now(),
    ).toMap());
  }
}

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final SessionModel? session;
  final String? errorMessage;

  AuthResult._({required this.isSuccess, this.user, this.session, this.errorMessage});

  factory AuthResult.success(UserModel user, SessionModel session) =>
      AuthResult._(isSuccess: true, user: user, session: session);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
