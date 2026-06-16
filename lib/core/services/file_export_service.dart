import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';

class FileExportService {
  Future<String> saveBackupJson(Map<String, dynamic> data) async {
    final dir = await _getBackupDir();
    final fileName = 'rkfm_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file.path;
  }

  Future<String> saveLogsCsv(String csv) async {
    final dir = await _getBackupDir();
    final fileName = 'rkfm_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(csv);
    return file.path;
  }

  Future<String> getRecordingDir(String programName) async {
    final now = DateTime.now();
    final base = await getExternalStorageDirectory();
    final root = base ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(
      root.path,
      AppConstants.recordingsRoot,
      '${now.year}',
      now.month.toString().padLeft(2, '0'),
      now.day.toString().padLeft(2, '0'),
      programName,
    ));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<Directory> _getBackupDir() async {
    final base = await getExternalStorageDirectory();
    final root = base ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, AppConstants.backupsRoot));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
