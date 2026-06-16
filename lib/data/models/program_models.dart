import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';

class ProgramCardModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? logoPath;
  final String? backgroundPath;
  final String templateId;
  final String facebookDestinationId;
  final String? rtmpDestinationId;
  final String programTitle;
  final String subtitle;
  final String tickerText;
  final String cameraProfileId;
  final String audioProfileId;
  final int bitrate;
  final String recordingProfileId;
  final String overlayProfileId;
  final int countdownDuration;
  final int cardColorValue;
  final String recordingPath;
  final bool isArchived;
  final bool isOutdoor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProgramCardModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoPath,
    this.backgroundPath,
    required this.templateId,
    required this.facebookDestinationId,
    this.rtmpDestinationId,
    required this.programTitle,
    required this.subtitle,
    required this.tickerText,
    required this.cameraProfileId,
    required this.audioProfileId,
    this.bitrate = 4000,
    required this.recordingProfileId,
    required this.overlayProfileId,
    this.countdownDuration = AppConstants.countdownDuration,
    required this.cardColorValue,
    required this.recordingPath,
    this.isArchived = false,
    this.isOutdoor = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgramCardModel.fromMap(Map<String, dynamic> map) => ProgramCardModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        logoPath: map['logo_path'] as String?,
        backgroundPath: map['background_path'] as String?,
        templateId: map['template_id'] as String,
        facebookDestinationId: map['facebook_destination_id'] as String,
        rtmpDestinationId: map['rtmp_destination_id'] as String?,
        programTitle: map['program_title'] as String,
        subtitle: map['subtitle'] as String,
        tickerText: map['ticker_text'] as String,
        cameraProfileId: map['camera_profile_id'] as String,
        audioProfileId: map['audio_profile_id'] as String,
        bitrate: map['bitrate'] as int? ?? 4000,
        recordingProfileId: map['recording_profile_id'] as String,
        overlayProfileId: map['overlay_profile_id'] as String,
        countdownDuration: map['countdown_duration'] as int? ?? 10,
        cardColorValue: map['card_color'] as int,
        recordingPath: map['recording_path'] as String,
        isArchived: (map['is_archived'] as int? ?? 0) == 1,
        isOutdoor: (map['is_outdoor'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'logo_path': logoPath,
        'background_path': backgroundPath,
        'template_id': templateId,
        'facebook_destination_id': facebookDestinationId,
        'rtmp_destination_id': rtmpDestinationId,
        'program_title': programTitle,
        'subtitle': subtitle,
        'ticker_text': tickerText,
        'camera_profile_id': cameraProfileId,
        'audio_profile_id': audioProfileId,
        'bitrate': bitrate,
        'recording_profile_id': recordingProfileId,
        'overlay_profile_id': overlayProfileId,
        'countdown_duration': countdownDuration,
        'card_color': cardColorValue,
        'recording_path': recordingPath,
        'is_archived': isArchived ? 1 : 0,
        'is_outdoor': isOutdoor ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ProgramCardModel copyWith({
    String? programTitle,
    String? subtitle,
    String? tickerText,
    bool? isArchived,
  }) =>
      ProgramCardModel(
        id: id,
        name: name,
        description: description,
        logoPath: logoPath,
        backgroundPath: backgroundPath,
        templateId: templateId,
        facebookDestinationId: facebookDestinationId,
        rtmpDestinationId: rtmpDestinationId,
        programTitle: programTitle ?? this.programTitle,
        subtitle: subtitle ?? this.subtitle,
        tickerText: tickerText ?? this.tickerText,
        cameraProfileId: cameraProfileId,
        audioProfileId: audioProfileId,
        bitrate: bitrate,
        recordingProfileId: recordingProfileId,
        overlayProfileId: overlayProfileId,
        countdownDuration: countdownDuration,
        cardColorValue: cardColorValue,
        recordingPath: recordingPath,
        isArchived: isArchived ?? this.isArchived,
        isOutdoor: isOutdoor,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, name];
}

class FacebookDestinationModel extends Equatable {
  final String id;
  final String pageName;
  final String rtmpUrl;
  final String streamKey;
  final bool isActive;

  const FacebookDestinationModel({
    required this.id,
    required this.pageName,
    required this.rtmpUrl,
    required this.streamKey,
    this.isActive = true,
  });

  factory FacebookDestinationModel.fromMap(Map<String, dynamic> map) =>
      FacebookDestinationModel(
        id: map['id'] as String,
        pageName: map['page_name'] as String,
        rtmpUrl: map['rtmp_url'] as String,
        streamKey: map['stream_key'] as String,
        isActive: (map['is_active'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'page_name': pageName,
        'rtmp_url': rtmpUrl,
        'stream_key': streamKey,
        'is_active': isActive ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, pageName];
}

class TemplateModel extends Equatable {
  final String id;
  final String name;
  final TemplateCategory category;
  final bool isBuiltIn;
  final String elementsJson;
  final int width;
  final int height;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.category,
    this.isBuiltIn = false,
    required this.elementsJson,
    this.width = 1920,
    this.height = 1080,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateModel.fromMap(Map<String, dynamic> map) => TemplateModel(
        id: map['id'] as String,
        name: map['name'] as String,
        category: TemplateCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => TemplateCategory.news,
        ),
        isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
        elementsJson: map['elements_json'] as String,
        width: map['width'] as int? ?? 1920,
        height: map['height'] as int? ?? 1080,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'is_built_in': isBuiltIn ? 1 : 0,
        'elements_json': elementsJson,
        'width': width,
        'height': height,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  List<TemplateElement> get elements {
    final list = jsonDecode(elementsJson) as List<dynamic>;
    return list.map((e) => TemplateElement.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  List<Object?> get props => [id, name];
}

class TemplateElement extends Equatable {
  final String id;
  final String type;
  final String content;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final int zIndex;
  final String fontFamily;
  final double fontSize;
  final int color;
  final String animation;
  final bool locked;

  const TemplateElement({
    required this.id,
    required this.type,
    required this.content,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.opacity = 1,
    this.zIndex = 0,
    this.fontFamily = 'Roboto',
    this.fontSize = 24,
    this.color = 0xFFFFFFFF,
    this.animation = 'none',
    this.locked = false,
  });

  factory TemplateElement.fromMap(Map<String, dynamic> map) => TemplateElement(
        id: map['id'] as String,
        type: map['type'] as String,
        content: map['content'] as String,
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        width: (map['width'] as num).toDouble(),
        height: (map['height'] as num).toDouble(),
        rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
        opacity: (map['opacity'] as num?)?.toDouble() ?? 1,
        zIndex: map['zIndex'] as int? ?? 0,
        fontFamily: map['fontFamily'] as String? ?? 'Roboto',
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 24,
        color: map['color'] as int? ?? 0xFFFFFFFF,
        animation: map['animation'] as String? ?? 'none',
        locked: map['locked'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'content': content,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'opacity': opacity,
        'zIndex': zIndex,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'color': color,
        'animation': animation,
        'locked': locked,
      };

  TemplateElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    String? content,
    double? fontSize,
  }) =>
      TemplateElement(
        id: id,
        type: type,
        content: content ?? this.content,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        rotation: rotation ?? this.rotation,
        opacity: opacity ?? this.opacity,
        zIndex: zIndex,
        fontFamily: fontFamily,
        fontSize: fontSize ?? this.fontSize,
        color: color,
        animation: animation,
        locked: locked,
      );

  @override
  List<Object?> get props => [id, type, x, y];
}

class CameraProfileModel extends Equatable {
  final String id;
  final String name;
  final String cameraFacing;
  final double zoom;
  final String filter;
  final int fps;
  final bool backgroundBlur;
  final bool faceEnhancement;

  const CameraProfileModel({
    required this.id,
    required this.name,
    this.cameraFacing = 'rear',
    this.zoom = 1.0,
    this.filter = 'none',
    this.fps = 30,
    this.backgroundBlur = false,
    this.faceEnhancement = false,
  });

  factory CameraProfileModel.fromMap(Map<String, dynamic> map) => CameraProfileModel(
        id: map['id'] as String,
        name: map['name'] as String,
        cameraFacing: map['camera_facing'] as String? ?? 'rear',
        zoom: (map['zoom'] as num?)?.toDouble() ?? 1.0,
        filter: map['filter'] as String? ?? 'none',
        fps: map['fps'] as int? ?? 30,
        backgroundBlur: (map['background_blur'] as int? ?? 0) == 1,
        faceEnhancement: (map['face_enhancement'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'camera_facing': cameraFacing,
        'zoom': zoom,
        'filter': filter,
        'fps': fps,
        'background_blur': backgroundBlur ? 1 : 0,
        'face_enhancement': faceEnhancement ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, name];
}

class AudioProfileModel extends Equatable {
  final String id;
  final String name;
  final String inputSource;
  final double gain;
  final bool noiseGate;
  final bool compressor;
  final bool limiter;

  const AudioProfileModel({
    required this.id,
    required this.name,
    this.inputSource = 'builtin',
    this.gain = 1.0,
    this.noiseGate = true,
    this.compressor = true,
    this.limiter = true,
  });

  factory AudioProfileModel.fromMap(Map<String, dynamic> map) => AudioProfileModel(
        id: map['id'] as String,
        name: map['name'] as String,
        inputSource: map['input_source'] as String? ?? 'builtin',
        gain: (map['gain'] as num?)?.toDouble() ?? 1.0,
        noiseGate: (map['noise_gate'] as int? ?? 1) == 1,
        compressor: (map['compressor'] as int? ?? 1) == 1,
        limiter: (map['limiter'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'input_source': inputSource,
        'gain': gain,
        'noise_gate': noiseGate ? 1 : 0,
        'compressor': compressor ? 1 : 0,
        'limiter': limiter ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, name];
}

class AppSettingsModel extends Equatable {
  final String id;
  final int countdownDuration;
  final String resolution;
  final int bitrate;
  final int fps;
  final String audioInput;
  final double audioGain;
  final String recordingQuality;
  final String recordingPath;
  final bool autoRecord;
  final String pin;
  final int sessionTimeoutMinutes;
  final bool autoLogout;
  final String language;

  const AppSettingsModel({
    required this.id,
    this.countdownDuration = 10,
    this.resolution = '1920x1080',
    this.bitrate = 4000,
    this.fps = 30,
    this.audioInput = 'builtin',
    this.audioGain = 1.0,
    this.recordingQuality = '1080p',
    this.recordingPath = AppConstants.recordingsRoot,
    this.autoRecord = true,
    this.pin = AppConstants.defaultPin,
    this.sessionTimeoutMinutes = 30,
    this.autoLogout = true,
    this.language = 'en',
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) => AppSettingsModel(
        id: map['id'] as String,
        countdownDuration: map['countdown_duration'] as int? ?? 10,
        resolution: map['resolution'] as String? ?? '1920x1080',
        bitrate: map['bitrate'] as int? ?? 4000,
        fps: map['fps'] as int? ?? 30,
        audioInput: map['audio_input'] as String? ?? 'builtin',
        audioGain: (map['audio_gain'] as num?)?.toDouble() ?? 1.0,
        recordingQuality: map['recording_quality'] as String? ?? '1080p',
        recordingPath: map['recording_path'] as String? ?? AppConstants.recordingsRoot,
        autoRecord: (map['auto_record'] as int? ?? 1) == 1,
        pin: map['pin'] as String? ?? AppConstants.defaultPin,
        sessionTimeoutMinutes: map['session_timeout'] as int? ?? 30,
        autoLogout: (map['auto_logout'] as int? ?? 1) == 1,
        language: map['language'] as String? ?? 'en',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'countdown_duration': countdownDuration,
        'resolution': resolution,
        'bitrate': bitrate,
        'fps': fps,
        'audio_input': audioInput,
        'audio_gain': audioGain,
        'recording_quality': recordingQuality,
        'recording_path': recordingPath,
        'auto_record': autoRecord ? 1 : 0,
        'pin': pin,
        'session_timeout': sessionTimeoutMinutes,
        'auto_logout': autoLogout ? 1 : 0,
        'language': language,
      };

  AppSettingsModel copyWith({
    int? countdownDuration,
    String? resolution,
    int? bitrate,
    String? pin,
    int? sessionTimeoutMinutes,
    bool? autoRecord,
  }) =>
      AppSettingsModel(
        id: id,
        countdownDuration: countdownDuration ?? this.countdownDuration,
        resolution: resolution ?? this.resolution,
        bitrate: bitrate ?? this.bitrate,
        fps: fps,
        audioInput: audioInput,
        audioGain: audioGain,
        recordingQuality: recordingQuality,
        recordingPath: recordingPath,
        autoRecord: autoRecord ?? this.autoRecord,
        pin: pin ?? this.pin,
        sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
        autoLogout: autoLogout,
        language: language,
      );

  @override
  List<Object?> get props => [id];
}
