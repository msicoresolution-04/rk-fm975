import 'package:get_it/get_it.dart';
import 'package:rkfm_broadcast/core/services/file_export_service.dart';
import 'package:rkfm_broadcast/core/services/secure_storage_service.dart';
import 'package:rkfm_broadcast/data/database/app_database.dart';
import 'package:rkfm_broadcast/data/repositories/auth_repository.dart';
import 'package:rkfm_broadcast/data/repositories/program_repository.dart';
import 'package:rkfm_broadcast/data/seed/database_seeder.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/broadcast_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/settings_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(getIt()));
  getIt.registerLazySingleton<ProgramRepository>(() => ProgramRepository(getIt()));
  getIt.registerLazySingleton<LogRepository>(() => LogRepository(getIt()));
  getIt.registerLazySingleton<BackupRepository>(() => BackupRepository(getIt()));
  getIt.registerLazySingleton<FileExportService>(() => FileExportService());

  final seeder = DatabaseSeeder(getIt<AppDatabase>());
  await seeder.seedIfNeeded();

  getIt.registerFactory<AuthViewModel>(() => AuthViewModel(
        getIt<AuthRepository>(),
        getIt<LogRepository>(),
        getIt<SecureStorageService>(),
      ));
  getIt.registerFactory<DashboardViewModel>(() => DashboardViewModel(
        getIt<ProgramRepository>(),
      ));
  getIt.registerFactory<BroadcastViewModel>(() => BroadcastViewModel(
        getIt<ProgramRepository>(),
        getIt<LogRepository>(),
        getIt<AuthRepository>(),
      ));
  getIt.registerFactory<SettingsViewModel>(() => SettingsViewModel(
        getIt<ProgramRepository>(),
        getIt<LogRepository>(),
        getIt<BackupRepository>(),
        getIt<AuthRepository>(),
        getIt<SecureStorageService>(),
        getIt<FileExportService>(),
      ));
}
