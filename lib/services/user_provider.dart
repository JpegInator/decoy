import 'package:flutter/material.dart';
import 'package:decoy/db/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  
  User? get user => _user;

  void setUser(User newUser) {
    if (_user != newUser) {
      _user = newUser;
      _scheduleNotify();
    }
  }

  void clearUser() {
    if (_user != null) {
      _user = null;
      _scheduleNotify();
    }
  }

  void _scheduleNotify() {
    // Откладываем уведомление до завершения текущей сборки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }
}