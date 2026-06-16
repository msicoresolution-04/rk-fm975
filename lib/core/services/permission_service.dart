import 'package:rkfm_broadcast/core/constants/app_constants.dart';

class PermissionService {
  static final Map<UserRole, Set<PermissionKey>> _rolePermissions = {
    UserRole.superAdmin: PermissionKey.values.toSet(),
    UserRole.admin: {
      PermissionKey.createTemplates,
      PermissionKey.editTemplates,
      PermissionKey.deleteTemplates,
      PermissionKey.configureCameras,
      PermissionKey.configureAudio,
      PermissionKey.configureOverlays,
      PermissionKey.configureStreamingSettings,
      PermissionKey.configureFacebookDestinations,
      PermissionKey.configureRecordingSettings,
      PermissionKey.configureProgramCards,
      PermissionKey.viewLogs,
      PermissionKey.exportLogs,
      PermissionKey.backupSystem,
      PermissionKey.login,
      PermissionKey.selectProgram,
      PermissionKey.previewBroadcast,
      PermissionKey.startBroadcast,
      PermissionKey.stopBroadcast,
      PermissionKey.editProgramTitle,
      PermissionKey.editProgramSubtitle,
      PermissionKey.editTicker,
      PermissionKey.muteAudio,
      PermissionKey.unmuteAudio,
      PermissionKey.pauseRecording,
      PermissionKey.resumeRecording,
      PermissionKey.takeSnapshot,
      PermissionKey.monitorBroadcast,
      PermissionKey.managePrograms,
      PermissionKey.manageTemplates,
      PermissionKey.manageFacebookDestinations,
      PermissionKey.manageRtmpSettings,
      PermissionKey.manageCameraProfiles,
      PermissionKey.manageAudioProfiles,
      PermissionKey.manageRecordings,
    },
    UserRole.user: {
      PermissionKey.login,
      PermissionKey.selectProgram,
      PermissionKey.previewBroadcast,
      PermissionKey.startBroadcast,
      PermissionKey.stopBroadcast,
      PermissionKey.editProgramTitle,
      PermissionKey.editProgramSubtitle,
      PermissionKey.editTicker,
      PermissionKey.muteAudio,
      PermissionKey.unmuteAudio,
      PermissionKey.pauseRecording,
      PermissionKey.resumeRecording,
      PermissionKey.takeSnapshot,
      PermissionKey.monitorBroadcast,
    },
  };

  static bool hasPermission(UserRole role, PermissionKey permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static bool canAccessSettings(UserRole role) {
    return role == UserRole.superAdmin || role == UserRole.admin;
  }

  static bool canManageUsers(UserRole role) {
    return role == UserRole.superAdmin;
  }

  static bool canAccessLogs(UserRole role) {
    return role == UserRole.superAdmin || role == UserRole.admin;
  }

  static bool canEditTemplates(UserRole role) {
    return role == UserRole.superAdmin || role == UserRole.admin;
  }
}
