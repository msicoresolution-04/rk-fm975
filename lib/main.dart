import 'package:flutter/material.dart';
import 'package:rkfm_broadcast/app.dart';
import 'package:rkfm_broadcast/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencyInjection();
  runApp(const RkfmBroadcastApp());
}
