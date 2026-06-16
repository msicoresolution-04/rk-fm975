import 'package:equatable/equatable.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String passwordHash;
  final String salt;
  final UserRole role;
  final String displayName;
  final bool isActive;
  final bool mustChangePassword;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.role,
    required this.displayName,
    this.isActive = true,
    this.mustChangePassword = false,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        salt: map['salt'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => UserRole.user,
        ),
        displayName: map['display_name'] as String,
        isActive: (map['is_active'] as int? ?? 1) == 1,
        mustChangePassword: (map['must_change_password'] as int? ?? 0) == 1,
        failedLoginAttempts: map['failed_login_attempts'] as int? ?? 0,
        lockedUntil: map['locked_until'] != null
            ? DateTime.parse(map['locked_until'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
        lastLoginAt: map['last_login_at'] != null
            ? DateTime.parse(map['last_login_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'salt': salt,
        'role': role.name,
        'display_name': displayName,
        'is_active': isActive ? 1 : 0,
        'must_change_password': mustChangePassword ? 1 : 0,
        'failed_login_attempts': failedLoginAttempts,
        'locked_until': lockedUntil?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? passwordHash,
    String? salt,
    bool? isActive,
    bool? mustChangePassword,
    int? failedLoginAttempts,
    DateTime? lockedUntil,
    DateTime? lastLoginAt,
  }) =>
      UserModel(
        id: id,
        username: username,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
        role: role,
        displayName: displayName,
        isActive: isActive ?? this.isActive,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
        lockedUntil: lockedUntil,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );

  @override
  List<Object?> get props => [id, username, role];
}

class SessionModel extends Equatable {
  final String id;
  final String userId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        deviceId: map['device_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        expiresAt: DateTime.parse(map['expires_at'] as String),
        isActive: (map['is_active'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'device_id': deviceId,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': isActive ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, userId];
}

class LoginHistoryModel extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String deviceId;
  final bool success;
  final String? failureReason;
  final DateTime timestamp;

  const LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.deviceId,
    required this.success,
    this.failureReason,
    required this.timestamp,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map) => LoginHistoryModel(
        id: map['id'] as String,
        userId: map['user_id'] as String? ?? '',
        username: map['username'] as String,
        deviceId: map['device_id'] as String,
        success: (map['success'] as int? ?? 0) == 1,
        failureReason: map['failure_reason'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'username': username,
        'device_id': deviceId,
        'success': success ? 1 : 0,
        'failure_reason': failureReason,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, timestamp];
}

class AuditLogModel extends Equatable {
  final String id;
  final String? userId;
  final String username;
  final LogCategory category;
  final LogLevel level;
  final String action;
  final String? details;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    this.userId,
    required this.username,
    required this.category,
    required this.level,
    required this.action,
    this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) => AuditLogModel(
        id: map['id'] as String,
        userId: map['user_id'] as String?,
        username: map['username'] as String,
        category: LogCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => LogCategory.system,
        ),
        level: LogLevel.values.firstWhere(
          (l) => l.name == map['level'],
          orElse: () => LogLevel.info,
        ),
        action: map['action'] as String,
        details: map['details'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'username': username,
        'category': category.name,
        'level': level.name,
        'action': action,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, timestamp];
}
