// ignore_for_file: use_key_in_widget_constructors

import 'package:decoy/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'auth_screen.dart';
import 'db/user_model.dart';
import 'main_screen.dart';
import 'db/step_models.dart';
import 'services/isar_service.dart';
import 'package:decoy/services/step_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:decoy/services/deep_seek_service.dart';
import 'package:decoy/services/water_provider.dart';
import 'db/water_model.dart';
import 'package:decoy/services/water_service.dart';
import 'package:decoy/db/chat_model.dart';
void main() async {
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Yekaterinburg'));
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      UserSchema,
      StepRecordSchema,
      StepSettingsSchema,
      WaterRecordSchema,
      ChatMessageSchema,
    ],
    directory: dir.path,
  );

  await IsarService.init(isar);
  WaterService.init(isar); // Инициализация сервиса воды

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userId = prefs.getInt('userId');

  User? currentUser;
  if (isLoggedIn && userId != null) {
    currentUser = await isar.users.get(userId);
  }

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StepProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()), // Добавлен WaterProvider
        Provider<DeepSeekService>(
          create: (_) => DeepSeekService(apiKey: "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"),
        ),
      ],
      child: MyApp(isar: isar, currentUser: currentUser),
    ),
  );
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
      home: currentUser != null
          ? FutureBuilder(
              future: _initializeProviders(context, currentUser!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return MainScreen(isar: isar, currentUser: currentUser!);
                }
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              },
            )
          : AuthScreen(isar: isar),
    );
  }

  Future<void> _initializeProviders(BuildContext context, User user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUser(user);
    
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    stepProvider.updateSteps(await IsarService.getTodaySteps());
    
    // Инициализация данных о воде
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    await waterProvider.loadTodayWater();
  }
}