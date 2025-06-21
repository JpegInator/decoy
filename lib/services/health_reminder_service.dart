import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:decoy/db/step_models.dart';
import 'package:decoy/services/water_provider.dart';
import 'package:decoy/services/step_provider.dart';

class HealthReminderService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Random _random = Random();

  final WaterProvider _waterProvider;
  final StepProvider _stepProvider;
  final Isar _isar;

  // Last known stats and timestamps
  int _lastWaterConsumed = 0;
  DateTime _lastWaterChangeTime = DateTime.now();

  int _lastSteps = 0;
  DateTime _lastStepChangeTime = DateTime.now();

  int _dailyStepGoal = 10000;

  Timer? _periodicTimer;

  // Categories with 10 example phrases each - replace with your actual phrases
  final List<String> waterReminders = [
    "Пейте воду регулярно для поддержания здоровья.",
    "Не забывайте пить воду в течение дня.",
    "Вода помогает поддерживать энергию и концентрацию.",
    "Пейте стакан воды перед каждым приемом пищи.",
    "Регулярное питье воды улучшает обмен веществ.",
    "Вода помогает очищать организм от токсинов.",
    "Пейте воду, чтобы избежать обезвоживания.",
    "Начинайте день со стакана воды.",
    "Пейте воду после физической активности.",
    "Вода способствует здоровью кожи и волос.",
  ];

  final List<String> stepReminders = [
    "Время сделать несколько шагов!",
    "Двигайтесь больше для здоровья сердца.",
    "Прогулка улучшает настроение и самочувствие.",
    "Добавьте шаги в свой день для активности.",
    "Каждый шаг приближает к цели.",
    "Не сидите долго, встаньте и пройдитесь.",
    "Шаги помогают поддерживать форму.",
    "Двигайтесь, чтобы оставаться энергичным.",
    "Прогулка на свежем воздухе полезна для здоровья.",
    "Сделайте паузу и пройдитесь немного.",
  ];

  final List<String> stepGoalReached = [
    "Поздравляем! Вы достигли своей цели по шагам!",
    "Отличная работа! Цель по шагам выполнена.",
    "Вы молодец! Продолжайте в том же духе.",
    "Цель достигнута! Ваши усилия приносят результат.",
    "Вы сделали это! Гордимся вашим достижением.",
    "Шаги выполнены! Так держать!",
    "Вы на пути к здоровью! Цель достигнута.",
    "Отличный результат! Продолжайте движение.",
    "Вы достигли цели! Время для отдыха.",
    "Поздравляем с выполнением дневной цели!",
  ];

  final List<String> lowActivityNudges = [
    "Попробуйте немного подвигаться, это полезно.",
    "Небольшая активность улучшит ваше самочувствие.",
    "Двигайтесь чаще, чтобы оставаться здоровым.",
    "Маленькие шаги тоже важны, начните сейчас.",
    "Время для легкой разминки и движения.",
    "Активность помогает поддерживать энергию.",
    "Не забывайте делать перерывы для движения.",
    "Постарайтесь добавить шаги в свой день.",
    "Двигайтесь, чтобы улучшить настроение.",
    "Небольшая прогулка пойдет на пользу.",
  ];

  HealthReminderService(this._waterProvider, this._stepProvider, this._isar);

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Initialize last known values
    _lastWaterConsumed = _waterProvider.waterConsumed;
    _lastSteps = _stepProvider.steps;
    _lastWaterChangeTime = DateTime.now();
    _lastStepChangeTime = DateTime.now();

    // Load daily step goal from DB
    await _loadDailyStepGoal();

    // Start periodic timer to check reminders every 15 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(Duration(minutes: 15), (_) => checkAndSendReminders());
  }

  Future<void> _loadDailyStepGoal() async {
    final settings = await _isar.stepSettings.where().findFirst();
    if (settings != null) {
      _dailyStepGoal = settings.dailyGoal;
    }
  }

  Future<void> checkAndSendReminders() async {
    final currentWater = _waterProvider.waterConsumed;
    final currentSteps = _stepProvider.steps;
    final now = DateTime.now();

    // Check water consumption change
    if (currentWater != _lastWaterConsumed) {
      _lastWaterConsumed = currentWater;
      _lastWaterChangeTime = now;
    } else {
      final durationSinceWaterChange = now.difference(_lastWaterChangeTime);
      if (durationSinceWaterChange.inHours >= 3) {
        await sendWaterReminder();
        _lastWaterChangeTime = now; // reset timer after notification
      }
    }

    // Check steps change
    if (currentSteps != _lastSteps) {
      final stepDiff = (currentSteps - _lastSteps).abs();
      if (stepDiff >= 500) {
        _lastStepChangeTime = now;
      }
      _lastSteps = currentSteps;
    } else {
      final durationSinceStepChange = now.difference(_lastStepChangeTime);
      if (durationSinceStepChange.inHours >= 3) {
        await sendStepReminder();
        _lastStepChangeTime = now; // reset timer after notification
      }
    }

    // Check if daily step goal reached
    if (currentSteps >= _dailyStepGoal) {
      await sendStepGoalReached();
      // Optionally reset or mark goal reached to avoid repeated notifications
    }

    // Check low activity nudges at 20:00 UTC+5
    final utcNow = now.toUtc();
    final utcPlus5Hour = utcNow.add(Duration(hours: 5));
    if (utcPlus5Hour.hour == 20 && utcPlus5Hour.minute == 0) {
      // Calculate step and water changes in last 3 hours
      final stepChange = (currentSteps - _lastSteps);
      final waterChange = (currentWater - _lastWaterConsumed);
      if (stepChange < 2000 && waterChange < 500) {
        await sendLowActivityNudge();
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'health_reminder_channel',
      'Health Reminders',
      channelDescription: 'Notifications to encourage healthy lifestyle',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      platformDetails,
      payload: 'health_reminder',
    );
  }

  String _getRandomPhrase(List<String> phrases) {
    if (phrases.isEmpty) return '';
    return phrases[_random.nextInt(phrases.length)];
  }

  Future<void> sendWaterReminder() async {
    final phrase = _getRandomPhrase(waterReminders);
    if (phrase.isNotEmpty) {
      await _showNotification('Напоминание о воде', phrase);
    }
  }

  Future<void> sendStepReminder() async {
    final phrase = _getRandomPhrase(stepReminders);
    if (phrase.isNotEmpty) {
      await _showNotification('Напоминание о шагах', phrase);
    }
  }

  Future<void> sendStepGoalReached() async {
    final phrase = _getRandomPhrase(stepGoalReached);
    if (phrase.isNotEmpty) {
      await _showNotification('Цель по шагам достигнута', phrase);
    }
  }

  Future<void> sendLowActivityNudge() async {
    final phrase = _getRandomPhrase(lowActivityNudges);
    if (phrase.isNotEmpty) {
      await _showNotification('Пониженная активность', phrase);
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
  }
}
