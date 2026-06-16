import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rkfm_broadcast/app.dart';
import 'package:rkfm_broadcast/core/di/injection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await setupDependencyInjection();
  runApp(const RkfmBroadcastApp());
}
