class AppConstants {
  static const appName = 'RKFM 97.5 Broadcast';
  static const appTagline = 'Powered By MSiCore Solution';
  static const defaultPin = '9750';
  static const sessionTimeoutMinutes = 30;
  static const countdownDuration = 10;
  static const maxLoginAttempts = 5;
  static const lockoutMinutes = 15;
  static const minPasswordLength = 8;
  static const designWidth = 1920.0;
  static const designHeight = 1080.0;

  static const cameraChannel = 'com.msicore.rkfm/camera';
  static const rtmpChannel = 'com.msicore.rkfm/rtmp';
  static const rtmpEventsChannel = 'com.msicore.rkfm/rtmp_events';
  static const audioChannel = 'com.msicore.rkfm/audio';
  static const audioMeterChannel = 'com.msicore.rkfm/audio_meter';
  static const systemChannel = 'com.msicore.rkfm/system';
  static const recordingChannel = 'com.msicore.rkfm/recording';

  static const facebookRtmpUrl = 'rtmps://live-api-s.facebook.com:443/rtmp/';

  static const recordingsRoot = 'RKFM/Recordings';
  static const snapshotsRoot = 'RKFM/snapshots';
  static const backupsRoot = 'RKFM/backups';
}

enum UserRole { superAdmin, admin, user }

enum LogLevel { info, warning, error, audit }

enum LogCategory {
  login,
  logout,
  program,
  recording,
  template,
  stream,
  system,
  security,
  error,
}

enum StreamDestinationType { facebook, youtube, customRtmp }

enum TemplateCategory {
  news,
  breakingNews,
  morningShow,
  podcast,
  interview,
  talkShow,
  musicProgram,
  communityProgram,
  sportsUpdate,
  weatherReport,
  electionCoverage,
  specialEvent,
  emergencyBroadcast,
  outdoorBroadcast,
}

enum BroadcastStatus { idle, preparing, countdown, live, stopping, error }

enum PermissionKey {
  fullSystemAccess,
  manageUsers,
  createUsers,
  editUsers,
  disableUsers,
  deleteUsers,
  resetPasswords,
  managePrograms,
  manageTemplates,
  manageFacebookDestinations,
  manageRtmpSettings,
  manageCameraProfiles,
  manageAudioProfiles,
  manageRecordings,
  manageStorage,
  manageLogs,
  exportData,
  importData,
  backupSystem,
  restoreSystem,
  maintenanceMode,
  databaseTools,
  manageSecurityPolicies,
  managePinSettings,
  forceEndBroadcast,
  forceLogoutUsers,
  createTemplates,
  editTemplates,
  deleteTemplates,
  configureCameras,
  configureAudio,
  configureOverlays,
  configureStreamingSettings,
  configureFacebookDestinations,
  configureRecordingSettings,
  configureProgramCards,
  viewLogs,
  exportLogs,
  login,
  selectProgram,
  previewBroadcast,
  startBroadcast,
  stopBroadcast,
  editProgramTitle,
  editProgramSubtitle,
  editTicker,
  muteAudio,
  unmuteAudio,
  pauseRecording,
  resumeRecording,
  takeSnapshot,
  monitorBroadcast,
}
