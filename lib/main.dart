// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'auth_screen.dart';
import 'db/user_model.dart';
import 'main_screen.dart';
import 'db/step_models.dart';
import 'services/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserSchema,
    StepRecordSchema,
    StepSettingsSchema,
  ], directory: dir.path);

  await IsarService.init(isar);

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userId = prefs.getInt('userId');

  User? currentUser;
  if (isLoggedIn && userId != null) {
    currentUser = await isar.users.get(userId);
  }

  runApp(MyApp(isar: isar, currentUser: currentUser));
}

class MyApp extends StatelessWidget {
  final Isar isar;
  final User? currentUser;

  const MyApp({required this.isar, this.currentUser, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitaTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(
          0xFFDCEDC8,
        ), // Основной фон приложения
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Прозрачный AppBar
          elevation: 0, // Убираем тень
          iconTheme: IconThemeData(color: Colors.black), // Цвет иконок
          titleTextStyle: TextStyle(
            color: Colors.black, // Цвет текста
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          currentUser != null
              ? MainScreen(isar: isar, currentUser: currentUser!)
              : AuthScreen(isar: isar),
    );
  }
}
