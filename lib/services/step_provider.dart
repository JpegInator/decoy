import 'package:flutter/material.dart';
import 'package:decoy/services/isar_service.dart';
import 'package:decoy/db/step_models.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:isar/isar.dart';

class StepProvider with ChangeNotifier {
  int _steps = 0;
  int _dailyGoal = 10000;

  int get steps => _steps;
  int get dailyGoal => _dailyGoal;

  void updateSteps(int newSteps) {
    _steps = newSteps;
    notifyListeners();
  }

  void updateDailyGoal(int newGoal) {
    _dailyGoal = newGoal;
    notifyListeners();
  }

  Future<void> loadDailyGoal() async {
    final settings = await IsarService.getSettings();
    _dailyGoal = settings.dailyGoal;
    notifyListeners();
  }

  // Загружаем шаги за сегодня
  Future<void> loadTodaySteps(Isar isar) async {
    final today = _currentDateOnly();
    final record = await isar.stepRecords
        .where()
        .dateEqualTo(today)
        .findFirst();

    if (record != null) {
      _steps = record.steps;
    } else {
      _steps = 0;
    }
    notifyListeners();
  }

  DateTime _currentDateOnly() {
    final now = tz.TZDateTime.now(tz.getLocation('Asia/Yekaterinburg'));
    return DateTime(now.year, now.month, now.day);
  }
}