import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/native/native_bridge.dart';
import 'package:rkfm_broadcast/data/models/program_models.dart';
import 'package:rkfm_broadcast/data/models/user_models.dart';
import 'package:rkfm_broadcast/data/repositories/auth_repository.dart';
import 'package:rkfm_broadcast/data/repositories/program_repository.dart';

class BroadcastViewModel extends ChangeNotifier {
  final ProgramRepository _programRepository;
  final LogRepository _logRepository;
  final AuthRepository _authRepository;

  BroadcastViewModel(this._programRepository, this._logRepository, this._authRepository);

  BroadcastStatus _status = BroadcastStatus.idle;
  ProgramCardModel? _program;
  FacebookDestinationModel? _destination;
  TemplateModel? _template;
  CameraProfileModel? _cameraProfile;
  AudioProfileModel? _audioProfile;

  int _countdown = 0;
  Duration _liveDuration = Duration.zero;
  bool _isMuted = false;
  bool _isRecording = false;
  bool _recordingPaused = false;
  bool _facebookConnected = false;
  int _viewerCount = 0;
  int _bitrate = 4000;
  String? _recordingPath;
  Timer? _durationTimer;
  Timer? _countdownTimer;
  StreamSubscription? _rtmpSub;
  DateTime? _liveStartTime;

  BroadcastStatus get status => _status;
  ProgramCardModel? get program => _program;
  FacebookDestinationModel? get destination => _destination;
  TemplateModel? get template => _template;
  int get countdown => _countdown;
  Duration get liveDuration => _liveDuration;
  bool get isMuted => _isMuted;
  bool get isRecording => _isRecording;
  bool get recordingPaused => _recordingPaused;
  bool get facebookConnected => _facebookConnected;
  int get viewerCount => _viewerCount;
  int get bitrate => _bitrate;
  bool get isLive => _status == BroadcastStatus.live;

  Future<void> prepareBroadcast(ProgramCardModel program, UserModel user) async {
    _program = program;
    _status = BroadcastStatus.preparing;
    notifyListeners();

    _destination = await _programRepository.getFacebookDestination(program.facebookDestinationId);
    _template = await _programRepository.getTemplate(program.templateId);
    _cameraProfile = await _programRepository.getCameraProfile(program.cameraProfileId);
    _audioProfile = await _programRepository.getAudioProfile(program.audioProfileId);
    _bitrate = program.bitrate * 1000;

    await _logRepository.log(
      userId: user.id,
      username: user.username,
      category: LogCategory.program,
      level: LogLevel.info,
      action: 'Broadcast prepared',
      details: 'Program: ${program.name}',
    );

    notifyListeners();
  }

  void startCountdown() {
    if (_program == null) return;
    _status = BroadcastStatus.countdown;
    _countdown = _program!.countdownDuration;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdown > 1) {
        _countdown--;
        notifyListeners();
      } else {
        timer.cancel();
        await _goLive();
      }
    });

    _preloadResources();
  }

  Future<void> _preloadResources() async {
    await NativeBridge.initializeCamera();
    await NativeBridge.startCameraPreview();
    await NativeBridge.initializeAudio();

    if (_cameraProfile != null) {
      await NativeBridge.setCameraFilter(_cameraProfile!.filter);
      await NativeBridge.setCameraZoom(_cameraProfile!.zoom);
    }

    if (_audioProfile != null) {
      await NativeBridge.setAudioGain(_audioProfile!.gain);
    }
  }

  Future<void> _goLive() async {
    _status = BroadcastStatus.live;
    _liveStartTime = DateTime.now();
    notifyListeners();

    if (_destination != null) {
      _facebookConnected = await NativeBridge.connectRtmp(
        url: _destination!.rtmpUrl,
        streamKey: _destination!.streamKey,
        bitrate: _bitrate,
      );
    }

    _isRecording = true;
    _recordingPath = await NativeBridge.startRecording(_program?.name ?? 'broadcast');

    _rtmpSub?.cancel();
    _rtmpSub = NativeBridge.rtmpEventStream.listen((event) {
      if (event is Map) {
        final type = event['type'] as String?;
        if (type == 'connected') _facebookConnected = true;
        if (type == 'disconnected' || type == 'error') _facebookConnected = false;
        notifyListeners();
      }
    });

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_liveStartTime != null) {
        _liveDuration = DateTime.now().difference(_liveStartTime!);
        _viewerCount = 12 + (_liveDuration.inMinutes * 3);
        notifyListeners();
      }
    });

    await _logRepository.log(
      username: 'system',
      category: LogCategory.stream,
      level: LogLevel.info,
      action: 'Broadcast started',
      details: 'Program: ${_program?.name}, Destination: ${_destination?.pageName}',
    );

    notifyListeners();
  }

  void abortCountdown() {
    _countdownTimer?.cancel();
    _status = BroadcastStatus.idle;
    _countdown = 0;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      await NativeBridge.unmuteAudio();
    } else {
      await NativeBridge.muteAudio();
    }
    _isMuted = !_isMuted;
    notifyListeners();
  }

  Future<void> toggleRecordingPause() async {
    if (_recordingPaused) {
      await NativeBridge.resumeRecording();
    } else {
      await NativeBridge.pauseRecording();
    }
    _recordingPaused = !_recordingPaused;
    notifyListeners();
  }

  Future<String?> takeSnapshot() => NativeBridge.takeSnapshot();

  Future<void> switchCamera() async {
    await NativeBridge.switchCamera();
    notifyListeners();
  }

  Future<void> updateProgramTitle(String title) async {
    if (_program == null) return;
    _program = _program!.copyWith(programTitle: title);
    await _programRepository.updateProgram(_program!);
    notifyListeners();
  }

  Future<void> updateSubtitle(String subtitle) async {
    if (_program == null) return;
    _program = _program!.copyWith(subtitle: subtitle);
    await _programRepository.updateProgram(_program!);
    notifyListeners();
  }

  Future<void> updateTicker(String ticker) async {
    if (_program == null) return;
    _program = _program!.copyWith(tickerText: ticker);
    await _programRepository.updateProgram(_program!);
    notifyListeners();
  }

  Future<bool> stopBroadcast({required String username, String? userId, required String pin}) async {
    final validPin = await _authRepository.verifyPin(pin);
    if (!validPin) return false;

    _status = BroadcastStatus.stopping;
    notifyListeners();

    await NativeBridge.disconnectRtmp();
    final savedPath = await NativeBridge.stopRecording();
    if (savedPath != null) _recordingPath = savedPath;
    _durationTimer?.cancel();
    _countdownTimer?.cancel();
    _rtmpSub?.cancel();

    if (_program != null && _recordingPath != null) {
      await _programRepository.saveRecording(
        programId: _program!.id,
        programName: _program!.name,
        filePath: _recordingPath!,
        durationSeconds: _liveDuration.inSeconds,
      );
    }

    await _logRepository.log(
      userId: userId,
      username: username,
      category: LogCategory.program,
      level: LogLevel.audit,
      action: 'Broadcast stopped',
      details: 'Duration: ${_formatDuration(_liveDuration)}',
    );

    _status = BroadcastStatus.idle;
    _isRecording = false;
    _facebookConnected = false;
    _liveDuration = Duration.zero;
    _viewerCount = 0;
    notifyListeners();
    return true;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _countdownTimer?.cancel();
    _rtmpSub?.cancel();
    super.dispose();
  }
}
