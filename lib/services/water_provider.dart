import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterProvider with ChangeNotifier {
  int _waterConsumed = 0;
  int _dailyGoal = 2000;
  final List<int> _waterHistory = [];
  static const String _prefsKey = 'waterData';

  int get waterConsumed => _waterConsumed;
  int get dailyGoal => _dailyGoal;
  List<int> get waterHistory => _waterHistory;
  double get progressPercentage =>
      _dailyGoal == 0 ? 0.0 : (_waterConsumed / _dailyGoal).clamp(0.0, 1.0);
  bool get isDailyGoalAchieved => _waterConsumed >= _dailyGoal;

  // Загрузка сохраненных данных при инициализации
  Future<void> loadTodayWater() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_prefsKey);

    if (savedData != null) {
      final parts = savedData.split('|');
      if (parts.length == 2) {
        _waterConsumed = int.tryParse(parts[0]) ?? 0;
        _dailyGoal = int.tryParse(parts[1]) ?? 2000;
        notifyListeners();
      }
    }
  }

  // Сохранение данных
  Future<void> _saveWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, '$_waterConsumed|$_dailyGoal');
  }

  void updateWaterData(int consumed, int goal) {
    _waterConsumed = consumed;
    _dailyGoal = goal;
    _addToHistory(consumed);
    _saveWaterData();
    notifyListeners();
  }

  void addWater(int amount) {
    _waterConsumed += amount;
    _addToHistory(_waterConsumed);
    _saveWaterData();
    notifyListeners();
  }

  void addToDailyGoal(int amount) {
    _dailyGoal += amount;
    _saveWaterData();
    notifyListeners();
  }

  void resetWater() {
    _waterConsumed = 0;
    _addToHistory(0);
    _saveWaterData();
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal;
    _saveWaterData();
    notifyListeners();
  }

  void _addToHistory(int amount) {
    if (_waterHistory.isEmpty || _waterHistory.last != amount) {
      _waterHistory.add(amount);
      if (_waterHistory.length > 30) {
        _waterHistory.removeAt(0);
      }
    }
  }
}
