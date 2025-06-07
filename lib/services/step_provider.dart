import 'package:flutter/material.dart';

class StepProvider with ChangeNotifier {
  int _steps = 0;

  int get steps => _steps;

  void updateSteps(int newSteps) {
    _steps = newSteps;
    notifyListeners();
  }
}