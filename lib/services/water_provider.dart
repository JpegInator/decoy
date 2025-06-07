import 'package:flutter/material.dart';
import 'package:decoy/services/water_service.dart';

class WaterProvider with ChangeNotifier {
  int _waterConsumed = 0; // в миллилитрах

  int get waterConsumed => _waterConsumed;

  WaterProvider() {
    loadTodayWater();
  }

  Future<void> loadTodayWater() async {
    _waterConsumed = await WaterService.getTodayWater();
    notifyListeners();
  }

  Future<void> addWater(int milliliters) async {
    await WaterService.saveWater(milliliters);
    _waterConsumed += milliliters;
    notifyListeners();
  }

  Future<void> resetWater() async {
    await WaterService.resetTodayWater(); // Сбрасываем в базе данных
    _waterConsumed = 0; // Сбрасываем в памяти
    notifyListeners();
  }
}