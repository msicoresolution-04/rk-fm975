import 'package:flutter/foundation.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/services/permission_service.dart';
import 'package:rkfm_broadcast/core/services/secure_storage_service.dart';
import 'package:rkfm_broadcast/data/models/user_models.dart';
import 'package:rkfm_broadcast/data/repositories/auth_repository.dart';
import 'package:rkfm_broadcast/data/repositories/program_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LogRepository _logRepository;
  final SecureStorageService _secureStorage;

  AuthViewModel(this._authRepository, this._logRepository, this._secureStorage);

  UserModel? _currentUser;
  SessionModel? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  SessionModel? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _currentSession != null;

  bool hasPermission(PermissionKey permission) {
    if (_currentUser == null) return false;
    return PermissionService.hasPermission(_currentUser!.role, permission);
  }

  Future<bool> tryRestoreSession() async {
    final sessionId = await _secureStorage.read('active_session_id');
    if (sessionId == null) return false;

    final session = await _authRepository.getActiveSession(sessionId);
    if (session == null) return false;

    final user = await _authRepository.getUserById(session.userId);
    if (user == null || !user.isActive) return false;

    _currentSession = session;
    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(username, password);

    _isLoading = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }

    _currentUser = result.user;
    _currentSession = result.session;
    await _secureStorage.write('active_session_id', result.session!.id);

    await _logRepository.log(
      userId: _currentUser!.id,
      username: _currentUser!.username,
      category: LogCategory.login,
      level: LogLevel.audit,
      action: 'User logged in',
      details: 'Device session started',
    );

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (_currentSession != null) {
      await _authRepository.logout(_currentSession!.id);
      await _logRepository.log(
        userId: _currentUser?.id,
        username: _currentUser?.username ?? 'unknown',
        category: LogCategory.logout,
        level: LogLevel.audit,
        action: 'User logged out',
      );
    }
    await _secureStorage.delete('active_session_id');
    _currentUser = null;
    _currentSession = null;
    notifyListeners();
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;
    if (newPassword.length < AppConstants.minPasswordLength) {
      _errorMessage = 'Password must be at least ${AppConstants.minPasswordLength} characters';
      notifyListeners();
      return false;
    }
    final success = await _authRepository.changePassword(_currentUser!.id, newPassword);
    if (success) {
      _currentUser = _currentUser!.copyWith(mustChangePassword: false);
      notifyListeners();
    }
    return success;
  }

  Future<bool> verifyPin(String pin) => _authRepository.verifyPin(pin);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
