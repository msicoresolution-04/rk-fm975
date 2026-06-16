import 'package:flutter/services.dart';

class NativeBridge {
  static const camera = MethodChannel('com.msicore.rkfm/camera');
  static const rtmp = MethodChannel('com.msicore.rkfm/rtmp');
  static const rtmpEvents = EventChannel('com.msicore.rkfm/rtmp_events');
  static const audio = MethodChannel('com.msicore.rkfm/audio');
  static const audioMeter = EventChannel('com.msicore.rkfm/audio_meter');
  static const system = MethodChannel('com.msicore.rkfm/system');
  static const recording = MethodChannel('com.msicore.rkfm/recording');

  static Future<bool> initializeCamera() async {
    try {
      final result = await camera.invokeMethod<bool>('initialize');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> startCameraPreview() async {
    try {
      final result = await camera.invokeMethod<bool>('startPreview');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> switchCamera() async {
    try {
      final result = await camera.invokeMethod<bool>('switchCamera');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setCameraFilter(String filter) async {
    await camera.invokeMethod('setFilter', {'filter': filter});
  }

  static Future<void> setCameraZoom(double zoom) async {
    await camera.invokeMethod('setZoom', {'zoom': zoom});
  }

  static Future<Map<String, dynamic>> getCameraStatus() async {
    try {
      final result = await camera.invokeMethod<Map>('getStatus');
      return Map<String, dynamic>.from(result ?? {});
    } catch (_) {
      return {};
    }
  }

  static Future<bool> connectRtmp({
    required String url,
    required String streamKey,
    required int bitrate,
  }) async {
    try {
      final result = await rtmp.invokeMethod<bool>('connect', {
        'url': url,
        'streamKey': streamKey,
        'bitrate': bitrate,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> disconnectRtmp() async {
    try {
      final result = await rtmp.invokeMethod<bool>('disconnect');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getStreamHealth() async {
    try {
      final result = await rtmp.invokeMethod<Map>('getHealth');
      return Map<String, dynamic>.from(result ?? {});
    } catch (_) {
      return {};
    }
  }

  static Stream<dynamic> get rtmpEventStream => rtmpEvents.receiveBroadcastStream();

  static Future<bool> initializeAudio() async {
    try {
      final result = await audio.invokeMethod<bool>('initialize');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAudioGain(double gain) async {
    await audio.invokeMethod('setGain', {'gain': gain});
  }

  static Future<void> muteAudio() async => audio.invokeMethod('mute');

  static Future<void> unmuteAudio() async => audio.invokeMethod('unmute');

  static Stream<dynamic> get audioMeterStream => audioMeter.receiveBroadcastStream();

  static Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final result = await system.invokeMethod<Map>('getSystemStats');
      return Map<String, dynamic>.from(result ?? {});
    } catch (_) {
      return {'cpuUsage': 0, 'memoryUsage': 0};
    }
  }

  static Future<String> getDeviceId() async {
    try {
      final result = await system.invokeMethod<String>('getDeviceId');
      return result ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<String?> takeSnapshot() async {
    try {
      final result = await camera.invokeMethod<Map>('takeSnapshot');
      return result?['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> startRecording(String programName) async {
    try {
      final result = await recording.invokeMethod<Map>('startRecording', {
        'programName': programName,
      });
      return result?['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final result = await recording.invokeMethod<Map>('stopRecording');
      return result?['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> pauseRecording() async => recording.invokeMethod('pauseRecording');

  static Future<void> resumeRecording() async => recording.invokeMethod('resumeRecording');

  static Future<bool> testRtmpConnection({
    required String url,
    required String streamKey,
  }) async {
    return connectRtmp(url: url, streamKey: streamKey, bitrate: 2500000);
  }
}
