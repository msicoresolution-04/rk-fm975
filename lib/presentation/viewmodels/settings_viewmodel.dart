import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/native/native_bridge.dart';
import 'package:rkfm_broadcast/core/services/file_export_service.dart';
import 'package:rkfm_broadcast/core/services/permission_service.dart';
import 'package:rkfm_broadcast/core/services/secure_storage_service.dart';
import 'package:rkfm_broadcast/data/models/program_models.dart';
import 'package:rkfm_broadcast/data/models/user_models.dart';
import 'package:rkfm_broadcast/data/repositories/auth_repository.dart';
import 'package:rkfm_broadcast/data/repositories/program_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final ProgramRepository _programRepository;
  final LogRepository _logRepository;
  final BackupRepository _backupRepository;
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  final FileExportService _fileExport;

  SettingsViewModel(
    this._programRepository,
    this._logRepository,
    this._backupRepository,
    this._authRepository,
    this._secureStorage,
    this._fileExport,
  );

  AppSettingsModel _settings = const AppSettingsModel(id: 'default');
  List<FacebookDestinationModel> _destinations = [];
  List<TemplateModel> _templates = [];
  List<AuditLogModel> _logs = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _lastExportPath;

  AppSettingsModel get settings => _settings;
  List<FacebookDestinationModel> get destinations => _destinations;
  List<TemplateModel> get templates => _templates;
  List<AuditLogModel> get logs => _logs;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get lastExportPath => _lastExportPath;

  Future<void> load(UserRole role) async {
    _isLoading = true;
    notifyListeners();

    _settings = await _programRepository.getSettings();
    _destinations = await _programRepository.getAllFacebookDestinations();
    _templates = await _programRepository.getAllTemplates();

    if (PermissionService.canAccessLogs(role)) {
      _logs = await _logRepository.getLogs();
    }
    if (PermissionService.canManageUsers(role)) {
      _users = await _authRepository.getAllUsers();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings(AppSettingsModel settings, String username, String? userId) async {
    _settings = settings;
    await _programRepository.saveSettings(settings);
    await _logRepository.log(
      userId: userId,
      username: username,
      category: LogCategory.system,
      level: LogLevel.audit,
      action: 'Settings updated',
    );
    notifyListeners();
  }

  Future<void> updateStreamingSettings({
    required String resolution,
    required int bitrate,
    required int fps,
    required String username,
    String? userId,
  }) async {
    await saveSettings(
      _settings.copyWith(resolution: resolution, bitrate: bitrate),
      username,
      userId,
    );
  }

  Future<void> updatePin(String newPin, String username, String? userId) async {
    await saveSettings(_settings.copyWith(pin: newPin), username, userId);
  }

  Future<String> exportBackup() async {
    final data = await _backupRepository.exportAll();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportBackupToFile() async {
    final data = await _backupRepository.exportAll();
    _lastExportPath = await _fileExport.saveBackupJson(data);
    notifyListeners();
    return _lastExportPath!;
  }

  Future<String> exportLogsToFile() async {
    final csv = await _logRepository.exportLogs();
    _lastExportPath = await _fileExport.saveLogsCsv(csv);
    notifyListeners();
    return _lastExportPath!;
  }

  Future<String> exportLogs() => _logRepository.exportLogs();

  Future<bool> importBackupFromJson(String json, String username, String? userId) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      await _backupRepository.importAll(data);
      await _logRepository.log(
        userId: userId,
        username: username,
        category: LogCategory.system,
        level: LogLevel.audit,
        action: 'System restored from backup',
      );
      await load(UserRole.superAdmin);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> filterLogs({LogCategory? category, String? search}) async {
    _logs = await _logRepository.getLogs(category: category, search: search);
    notifyListeners();
  }

  Future<void> saveTemplate(TemplateModel template) async {
    await _programRepository.saveTemplate(template);
    _templates = await _programRepository.getAllTemplates();
    notifyListeners();
  }

  Future<FacebookDestinationModel> saveFacebookDestination({
    String? id,
    required String pageName,
    required String streamKey,
    String? rtmpUrl,
    String username = 'system',
    String? userId,
  }) async {
    final destination = FacebookDestinationModel(
      id: id ?? '',
      pageName: pageName,
      rtmpUrl: rtmpUrl ?? AppConstants.facebookRtmpUrl,
      streamKey: streamKey,
    );

    if (id == null || id.isEmpty) {
      final created = await _programRepository.createFacebookDestination(
        pageName: pageName,
        rtmpUrl: destination.rtmpUrl,
        streamKey: streamKey,
      );
      await _secureStorage.storeEncrypted('fb_key_${created.id}', streamKey);
      _destinations = await _programRepository.getAllFacebookDestinations();
      await _logRepository.log(
        userId: userId,
        username: username,
        category: LogCategory.stream,
        level: LogLevel.audit,
        action: 'Facebook destination created',
        details: pageName,
      );
      notifyListeners();
      return created;
    }

    await _programRepository.saveFacebookDestination(destination);
    await _secureStorage.storeEncrypted('fb_key_$id', streamKey);
    _destinations = await _programRepository.getAllFacebookDestinations();
    notifyListeners();
    return destination;
  }

  Future<void> deleteFacebookDestination(String id, String username, String? userId) async {
    await _programRepository.deleteFacebookDestination(id);
    await _secureStorage.delete('fb_key_$id');
    _destinations = await _programRepository.getAllFacebookDestinations();
    await _logRepository.log(
      userId: userId,
      username: username,
      category: LogCategory.stream,
      level: LogLevel.audit,
      action: 'Facebook destination deleted',
    );
    notifyListeners();
  }

  Future<bool> testFacebookConnection(String rtmpUrl, String streamKey) async {
    final connected = await NativeBridge.testRtmpConnection(url: rtmpUrl, streamKey: streamKey);
    await NativeBridge.disconnectRtmp();
    return connected;
  }

  Future<UserModel> createUser({
    required String username,
    required String password,
    required UserRole role,
    required String displayName,
    required String adminUsername,
    String? adminUserId,
  }) async {
    final user = await _authRepository.createUser(
      username: username,
      password: password,
      role: role,
      displayName: displayName,
    );
    _users = await _authRepository.getAllUsers();
    await _logRepository.log(
      userId: adminUserId,
      username: adminUsername,
      category: LogCategory.security,
      level: LogLevel.audit,
      action: 'User created',
      details: username,
    );
    notifyListeners();
    return user;
  }

  Future<void> toggleUserActive(UserModel user, String adminUsername, String? adminUserId) async {
    final db = await _authRepository.getUserById(user.id);
    if (db == null) return;
    final updated = db.copyWith(isActive: !db.isActive);
    // Update via auth repo - need to add method
    await _authRepository.updateUser(updated);
    _users = await _authRepository.getAllUsers();
    await _logRepository.log(
      userId: adminUserId,
      username: adminUsername,
      category: LogCategory.security,
      level: LogLevel.audit,
      action: updated.isActive ? 'User enabled' : 'User disabled',
      details: user.username,
    );
    notifyListeners();
  }
}
