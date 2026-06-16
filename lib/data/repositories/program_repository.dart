import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/data/database/app_database.dart';
import 'package:rkfm_broadcast/data/models/program_models.dart';
import 'package:rkfm_broadcast/data/models/user_models.dart';

class ProgramRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ProgramRepository(this._db);

  Future<List<ProgramCardModel>> getActivePrograms() async {
    final db = await _db.database;
    final results = await db.query(
      'program_cards',
      where: 'is_archived = 0',
      orderBy: 'name ASC',
    );
    return results.map(ProgramCardModel.fromMap).toList();
  }

  Future<ProgramCardModel?> getProgramById(String id) async {
    final db = await _db.database;
    final results = await db.query('program_cards', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return ProgramCardModel.fromMap(results.first);
  }

  Future<void> updateProgram(ProgramCardModel program) async {
    final db = await _db.database;
    await db.update('program_cards', program.toMap(), where: 'id = ?', whereArgs: [program.id]);
  }

  Future<ProgramCardModel> duplicateProgram(ProgramCardModel program) async {
    final now = DateTime.now();
    final duplicate = ProgramCardModel(
      id: _uuid.v4(),
      name: '${program.name} (Copy)',
      description: program.description,
      logoPath: program.logoPath,
      backgroundPath: program.backgroundPath,
      templateId: program.templateId,
      facebookDestinationId: program.facebookDestinationId,
      rtmpDestinationId: program.rtmpDestinationId,
      programTitle: program.programTitle,
      subtitle: program.subtitle,
      tickerText: program.tickerText,
      cameraProfileId: program.cameraProfileId,
      audioProfileId: program.audioProfileId,
      bitrate: program.bitrate,
      recordingProfileId: program.recordingProfileId,
      overlayProfileId: program.overlayProfileId,
      countdownDuration: program.countdownDuration,
      cardColorValue: program.cardColorValue,
      recordingPath: program.recordingPath,
      isOutdoor: program.isOutdoor,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('program_cards', duplicate.toMap());
    return duplicate;
  }

  Future<FacebookDestinationModel?> getFacebookDestination(String id) async {
    final db = await _db.database;
    final results = await db.query('facebook_destinations', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return FacebookDestinationModel.fromMap(results.first);
  }

  Future<List<FacebookDestinationModel>> getAllFacebookDestinations() async {
    final db = await _db.database;
    final results = await db.query('facebook_destinations', orderBy: 'page_name ASC');
    return results.map(FacebookDestinationModel.fromMap).toList();
  }

  Future<void> saveFacebookDestination(FacebookDestinationModel destination) async {
    final db = await _db.database;
    await db.insert(
      'facebook_destinations',
      destination.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFacebookDestination(String id) async {
    final db = await _db.database;
    await db.delete('facebook_destinations', where: 'id = ?', whereArgs: [id]);
  }

  Future<FacebookDestinationModel> createFacebookDestination({
    required String pageName,
    required String rtmpUrl,
    required String streamKey,
  }) async {
    final destination = FacebookDestinationModel(
      id: _uuid.v4(),
      pageName: pageName,
      rtmpUrl: rtmpUrl,
      streamKey: streamKey,
    );
    await saveFacebookDestination(destination);
    return destination;
  }

  Future<TemplateModel?> getTemplate(String id) async {
    final db = await _db.database;
    final results = await db.query('templates', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return TemplateModel.fromMap(results.first);
  }

  Future<List<TemplateModel>> getAllTemplates() async {
    final db = await _db.database;
    final results = await db.query('templates', orderBy: 'name ASC');
    return results.map(TemplateModel.fromMap).toList();
  }

  Future<void> saveTemplate(TemplateModel template) async {
    final db = await _db.database;
    await db.insert('templates', template.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CameraProfileModel?> getCameraProfile(String id) async {
    final db = await _db.database;
    final results = await db.query('camera_profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return CameraProfileModel.fromMap(results.first);
  }

  Future<AudioProfileModel?> getAudioProfile(String id) async {
    final db = await _db.database;
    final results = await db.query('audio_profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return AudioProfileModel.fromMap(results.first);
  }

  Future<AppSettingsModel> getSettings() async {
    final db = await _db.database;
    final results = await db.query('app_settings', limit: 1);
    if (results.isEmpty) {
      return const AppSettingsModel(id: 'default');
    }
    return AppSettingsModel.fromMap(results.first);
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    final db = await _db.database;
    await db.insert('app_settings', settings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveRecording({
    required String programId,
    required String programName,
    required String filePath,
    required int durationSeconds,
    String resolution = '1920x1080',
  }) async {
    final db = await _db.database;
    await db.insert('recordings', {
      'id': _uuid.v4(),
      'program_id': programId,
      'program_name': programName,
      'file_path': filePath,
      'duration_seconds': durationSeconds,
      'resolution': resolution,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

class LogRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  LogRepository(this._db);

  Future<void> log({
    String? userId,
    required String username,
    required LogCategory category,
    required LogLevel level,
    required String action,
    String? details,
  }) async {
    final db = await _db.database;
    await db.insert('audit_logs', AuditLogModel(
      id: _uuid.v4(),
      userId: userId,
      username: username,
      category: category,
      level: level,
      action: action,
      details: details,
      timestamp: DateTime.now(),
    ).toMap());
  }

  Future<List<AuditLogModel>> getLogs({
    LogCategory? category,
    String? search,
    int limit = 500,
  }) async {
    final db = await _db.database;
    String? where;
    List<dynamic>? whereArgs;

    if (category != null && search != null && search.isNotEmpty) {
      where = 'category = ? AND (action LIKE ? OR details LIKE ? OR username LIKE ?)';
      whereArgs = [category.name, '%$search%', '%$search%', '%$search%'];
    } else if (category != null) {
      where = 'category = ?';
      whereArgs = [category.name];
    } else if (search != null && search.isNotEmpty) {
      where = 'action LIKE ? OR details LIKE ? OR username LIKE ?';
      whereArgs = ['%$search%', '%$search%', '%$search%'];
    }

    final results = await db.query(
      'audit_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return results.map(AuditLogModel.fromMap).toList();
  }

  Future<String> exportLogs() async {
    final logs = await getLogs(limit: 10000);
    final buffer = StringBuffer('timestamp,username,category,level,action,details\n');
    for (final log in logs) {
      buffer.writeln(
        '${log.timestamp.toIso8601String()},${log.username},${log.category.name},'
        '${log.level.name},"${log.action}","${log.details ?? ''}"',
      );
    }
    return buffer.toString();
  }
}

class BackupRepository {
  final AppDatabase _db;

  BackupRepository(this._db);

  Future<Map<String, dynamic>> exportAll() async {
    final db = await _db.database;
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'users': await db.query('users'),
      'program_cards': await db.query('program_cards'),
      'templates': await db.query('templates'),
      'facebook_destinations': await db.query('facebook_destinations'),
      'camera_profiles': await db.query('camera_profiles'),
      'audio_profiles': await db.query('audio_profiles'),
      'app_settings': await db.query('app_settings'),
      'audit_logs': await db.query('audit_logs', limit: 5000),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final table in [
        'audit_logs',
        'sessions',
        'login_history',
        'recordings',
        'program_cards',
        'templates',
        'facebook_destinations',
        'camera_profiles',
        'audio_profiles',
        'app_settings',
        'users',
      ]) {
        await txn.delete(table);
      }

      Future<void> insertRows(String table, dynamic rows) async {
        if (rows is! List) return;
        for (final row in rows) {
          if (row is Map) {
            await txn.insert(table, Map<String, dynamic>.from(row));
          }
        }
      }

      await insertRows('users', data['users']);
      await insertRows('facebook_destinations', data['facebook_destinations']);
      await insertRows('camera_profiles', data['camera_profiles']);
      await insertRows('audio_profiles', data['audio_profiles']);
      await insertRows('templates', data['templates']);
      await insertRows('program_cards', data['program_cards']);
      await insertRows('app_settings', data['app_settings']);
      await insertRows('audit_logs', data['audit_logs']);
    });
  }
}
