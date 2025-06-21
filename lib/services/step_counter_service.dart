import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'isar_service.dart';
import 'dart:async';

class StepCounterService {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  Timer? _dayCheckTimer;

  Future<void> init() async {
    await Permission.activityRecognition.request();
    await _checkDayChange();
    
    _steps = await IsarService.getTodaySteps();
    
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount);
    
    _startDayCheckTimer();
  }
  
   Future<void> _checkDayChange() async {
    if (await IsarService.isNewDay()) {
      _steps = 0;
      await IsarService.saveSteps(_steps);
    } else {
      _steps = await IsarService.getTodaySteps();
    }
  }

  void _startDayCheckTimer() {
    _dayCheckTimer?.cancel();
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkDayChange();
    });
  }

  void dispose() {
    _dayCheckTimer?.cancel();
  }

  static Future<bool> checkAndRequestPermissions() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  void _onStepCount(StepCount event) async {
    _steps = event.steps;
    await IsarService.saveSteps(_steps);
  }

  int get currentSteps => _steps;
}
