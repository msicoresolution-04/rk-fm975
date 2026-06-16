import 'package:rkfm_broadcast/core/services/install_service.dart';

class InstallServiceStub implements InstallService {
  @override
  InstallPlatform get platform => InstallPlatform.unknown;

  @override
  bool get canInstall => false;

  @override
  bool get isInstalled => true;

  @override
  String get platformLabel => 'Native App';

  @override
  Future<void> install() async {}

  @override
  Future<void> checkInstallState() async {}
}

InstallService createInstallService() => InstallServiceStub();
