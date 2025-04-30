import 'package:isar/isar.dart';

part 'step_models.g.dart';

@collection
class StepRecord {
  Id id = Isar.autoIncrement;
  
  @Index()
  final DateTime date;
  int steps;
  bool goalAchieved;

  StepRecord({
    required this.date,
    required this.steps,
    this.goalAchieved = false,
  });
}

@collection
class StepSettings {
  Id id = Isar.autoIncrement; // Уникальный идентификатор записи
  
  // Дневная цель по шагам (по умолчанию 10 000)
  int dailyGoal = 10000;

  // Включены ли уведомления
  bool notificationsEnabled = true;

  // Время уведомления (часы)
  int notificationHour = 12; // По умолчанию 12:00

  // Время уведомления (минуты)
  int notificationMinute = 0;

  // Конструктор
  StepSettings({
    this.dailyGoal = 10000,
    this.notificationsEnabled = true,
    this.notificationHour = 12,
    this.notificationMinute = 0,
  });

  @ignore
  String get notificationTimeString {
    final hour = notificationHour.toString().padLeft(2, '0');
    final minute = notificationMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}