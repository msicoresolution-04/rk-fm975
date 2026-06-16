enum InstallPlatform { android, ios, web, desktop, unknown }

abstract class InstallService {
  InstallPlatform get platform;
  bool get canInstall;
  bool get isInstalled;
  String get platformLabel;

  Future<void> install();
  Future<void> checkInstallState();
}
