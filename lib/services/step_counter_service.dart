import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'isar_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class StepCounterService {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  late FlutterLocalNotificationsPlugin _notifications;

  Future<void> init() async {
    await Permission.activityRecognition.request();
    await Permission.notification.request();
    
    _steps = await IsarService.getTodaySteps();
    
    _notifications = FlutterLocalNotificationsPlugin();
    await _initNotifications();
    
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount);
    
    _checkDailyGoal();
    _scheduleDailyNotification();
  }
  
  static Future<bool> checkAndRequestPermissions() async {
  final status = await Permission.activityRecognition.request();
  return status.isGranted;
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('app_icon');
      
    final InitializationSettings initializationSettings = 
      InitializationSettings(android: initializationSettingsAndroid);
      
    await _notifications.initialize(initializationSettings);
  }

  void _onStepCount(StepCount event) async {
    _steps = event.steps;
    await IsarService.saveSteps(_steps);
    _checkDailyGoal();
  }

  Future<void> _checkDailyGoal() async {
    final settings = await IsarService.getSettings();
    if (_steps >= settings.dailyGoal) {
      await _showNotification(
        'Поздравляем!',
        'Вы достигли дневной цели!',
      );
    }
  }

  Future<void> _scheduleDailyNotification() async {
    final settings = await IsarService.getSettings();
    if (!settings.notificationsEnabled) return;
    
    final now = tz.TZDateTime.now(tz.getLocation('Asia/Yekaterinburg'));
    var scheduledDate = tz.TZDateTime(
      tz.getLocation('Asia/Yekaterinburg'),
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _notifications.zonedSchedule(
      0,
      'Не забывайте про активность!',
      'Ваша дневная цель: ${settings.dailyGoal} шагов',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'step_reminder',
          'Напоминания о шагах',
          channelDescription: 'Напоминания о необходимости ходить',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation: 
        UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _showNotification(String title, String body) async {
    await _notifications.show(
      1,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'step_goal',
          'Достижение цели',
          channelDescription: 'Уведомления о достижении цели',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  int get currentSteps => _steps;
}