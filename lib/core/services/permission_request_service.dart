import 'package:permission_handler/permission_handler.dart';

class PermissionRequestService {
  static Future<bool> requestBroadcastPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
    ];

    final statuses = await permissions.request();
    final camera = statuses[Permission.camera]?.isGranted ?? false;
    final mic = statuses[Permission.microphone]?.isGranted ?? false;
    return camera && mic;
  }

  static Future<bool> hasRequiredPermissions() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    return camera && mic;
  }
}
