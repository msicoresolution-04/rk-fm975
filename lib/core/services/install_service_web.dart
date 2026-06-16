import 'dart:js_interop';
import 'package:rkfm_broadcast/core/services/install_service.dart';

@JS('rkfmInstall')
external _RkfmInstall get _install;

@JS()
extension type _RkfmInstall._(JSObject _) implements JSObject {
  external String get platform;
  external bool get canInstall;
  external bool get isInstalled;
  external String get platformLabel;
  external JSPromise<JSAny?> install();
  external JSPromise<JSAny?> checkState();
}

class InstallServiceWeb implements InstallService {
  InstallPlatform _platform = InstallPlatform.unknown;
  bool _canInstall = true;
  bool _isInstalled = false;
  String _label = 'Web';

  InstallServiceWeb() {
    checkInstallState();
  }

  @override
  InstallPlatform get platform => _platform;

  @override
  bool get canInstall => _canInstall;

  @override
  bool get isInstalled => _isInstalled;

  @override
  String get platformLabel => _label;

  @override
  Future<void> checkInstallState() async {
    try {
      await _install.checkState().toDart;
      _mapFromJs();
    } catch (_) {}
  }

  @override
  Future<void> install() async {
    await _install.install().toDart;
    await checkInstallState();
  }

  void _mapFromJs() {
    _label = _install.platformLabel;
    _canInstall = _install.canInstall;
    _isInstalled = _install.isInstalled;
    _platform = switch (_install.platform) {
      'android' => InstallPlatform.android,
      'ios' => InstallPlatform.ios,
      'web' => InstallPlatform.web,
      'desktop' => InstallPlatform.desktop,
      _ => InstallPlatform.unknown,
    };
  }
}

InstallService createInstallService() => InstallServiceWeb();
