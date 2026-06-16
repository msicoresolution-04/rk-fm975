import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rkfm_broadcast/core/native/native_bridge.dart';
import 'package:rkfm_broadcast/data/models/program_models.dart';
import 'package:rkfm_broadcast/data/repositories/program_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ProgramRepository _programRepository;

  DashboardViewModel(this._programRepository);

  List<ProgramCardModel> _programs = [];
  ProgramCardModel? _selectedProgram;
  FacebookDestinationModel? _selectedDestination;
  bool _isLoading = true;
  bool _isConnected = true;
  int _cpuUsage = 0;
  int _memoryUsage = 0;
  double _audioLeft = -60;
  double _audioRight = -60;
  Timer? _monitorTimer;
  StreamSubscription? _audioSub;

  List<ProgramCardModel> get programs => _programs;
  ProgramCardModel? get selectedProgram => _selectedProgram;
  FacebookDestinationModel? get selectedDestination => _selectedDestination;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get cpuUsage => _cpuUsage;
  int get memoryUsage => _memoryUsage;
  double get audioLeft => _audioLeft;
  double get audioRight => _audioRight;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _programs = await _programRepository.getActivePrograms();
    await NativeBridge.initializeCamera();
    await NativeBridge.initializeAudio();
    await NativeBridge.startCameraPreview();

    _startMonitoring();
    _isLoading = false;
    notifyListeners();
  }

  void selectProgram(ProgramCardModel program) {
    _selectedProgram = program;
    _loadDestination(program.facebookDestinationId);
    notifyListeners();
  }

  Future<void> _loadDestination(String id) async {
    _selectedDestination = await _programRepository.getFacebookDestination(id);
    notifyListeners();
  }

  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final connectivity = await Connectivity().checkConnectivity();
      _isConnected = !connectivity.contains(ConnectivityResult.none);

      final stats = await NativeBridge.getSystemStats();
      _cpuUsage = stats['cpuUsage'] as int? ?? 0;
      _memoryUsage = stats['memoryUsage'] as int? ?? 0;
      notifyListeners();
    });

    _audioSub?.cancel();
    _audioSub = NativeBridge.audioMeterStream.listen((data) {
      if (data is Map) {
        _audioLeft = (data['left'] as num?)?.toDouble() ?? -60;
        _audioRight = (data['right'] as num?)?.toDouble() ?? -60;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _audioSub?.cancel();
    super.dispose();
  }
}
