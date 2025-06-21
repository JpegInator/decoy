// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/services.dart';
import 'auth_screen.dart';
import 'db/user_model.dart';
import 'db/step_models.dart';
import 'db/water_model.dart';
import 'db/chat_model.dart';
import 'services/isar_service.dart';
import 'services/water_service.dart';
import 'services/user_provider.dart';
import 'services/step_provider.dart';
import 'services/water_provider.dart';
import 'services/deep_seek_service.dart';
import 'services/step_counter_service.dart';
import 'services/health_reminder_service.dart';
import 'app_theme.dart';
import 'main_screen.dart';

void main() async {
  // Инициализация временных зон
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Yekaterinburg'));

  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserSchema,
    StepRecordSchema,
    StepSettingsSchema,
    WaterRecordSchema,
    ChatMessageSchema,
  ], directory: dir.path);

  // Инициализация сервисов
  await IsarService.init(isar);
  await WaterService.init(isar);

  // Инициализация сервисов состояния
  final stepCounterService = StepCounterService();
  final waterProvider = WaterProvider();
  final stepProvider = StepProvider();
  final healthReminderService = HealthReminderService(
    waterProvider,
    stepProvider,
    isar,
  );
  final deepSeekService = DeepSeekService(
    apiKey:
        "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",
  );

  // Проверка авторизации
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userId = prefs.getInt('userId');

  User? currentUser;
  if (isLoggedIn && userId != null) {
    currentUser = await isar.users.get(userId);
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => stepProvider),
        ChangeNotifierProvider(create: (_) => waterProvider),
        Provider<StepCounterService>(create: (_) => stepCounterService),
        Provider<HealthReminderService>(create: (_) => healthReminderService),
        Provider<DeepSeekService>(create: (_) => deepSeekService),
      ],
      child: MyApp(
        isar: isar,
        currentUser: currentUser,
        stepCounterService: stepCounterService,
        healthReminderService: healthReminderService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Isar isar;
  final User? currentUser;
  final StepCounterService stepCounterService;
  final HealthReminderService healthReminderService;

  const MyApp({
    Key? key,
    required this.isar,
    this.currentUser,
    required this.stepCounterService,
    required this.healthReminderService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitaTrack',
      theme: appTheme,
              home:
          currentUser != null
              ? FutureBuilder(
                  future: _initializeProviders(context, currentUser!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        body: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.mainGradient,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return MainScreen(
                        isar: isar,
                        currentUser: currentUser!,
                        stepCounterService: stepCounterService,
                        healthReminderService: healthReminderService,
                      );
                    }
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

    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    await waterProvider.loadTodayWater();
  }
}
