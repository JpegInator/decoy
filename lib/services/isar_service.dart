import 'package:isar/isar.dart';
import 'package:timezone/timezone.dart' as tz;
import '../db/step_models.dart';

class IsarService {
  static late Isar isar;

  static Future<void> init(Isar isarInstance) async {
    isar = isarInstance;

    if (await isar.stepSettings.count() == 0) {
      await isar.writeTxn(() async {
        await isar.stepSettings.put(StepSettings(
          dailyGoal: 10000, // Default daily goal of 10,000 steps
          notificationHour: 12,
          notificationMinute: 0,
        ));
      });
    }
  }
  // Методы для работы с шагами
  static Future<void> saveSteps(int steps) async {
    final today = currentDate();
    final existingRecord = await isar.stepRecords
        .filter()
        .dateEqualTo(today)
        .findFirst();

    final settings = await getSettings();
    final goalAchieved = steps >= settings.dailyGoal;

    if (existingRecord != null) {
      await isar.writeTxn(() async {
        existingRecord.steps = steps;
        existingRecord.goalAchieved = goalAchieved;
        await isar.stepRecords.put(existingRecord);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.stepRecords.put(StepRecord(
          date: today,
          steps: steps,
          goalAchieved: goalAchieved,
        ));
      });
    }
  }

  static Future<int> getTodaySteps() async {
    final record = await isar.stepRecords
        .filter()
        .dateEqualTo(currentDate())
        .findFirst();
    return record?.steps ?? 0;
  }

  static Future<List<StepRecord>> getStepsForPeriod(DateTime start, DateTime end) async {
    return await isar.stepRecords
        .filter()
        .dateBetween(start, end)
        .sortByDate()
        .findAll();
  }

  // Методы для работы с настройками
  static Future<StepSettings> getSettings() async {
    final settings = await isar.stepSettings.where().findFirst();
    return settings ?? StepSettings(
      dailyGoal: 10000,
      notificationHour: 12,
      notificationMinute: 0,
    );
  }

  static Future<void> updateSettings(StepSettings settings) async {
    await isar.writeTxn(() async {
      if (settings.id == 0) {
        // Fetch existing settings to get the id
        final existing = await isar.stepSettings.where().findFirst();
        if (existing != null) {
          settings.id = existing.id;
        }
      }
      await isar.stepSettings.put(settings);
    });
  }

  // Вспомогательные методы
  static DateTime currentDate() {
    final now = tz.TZDateTime.now(tz.local);
    return DateTime(now.year, now.month, now.day);
  }

  static Future<bool> isNewDay() async {
    final lastRecord = await isar.stepRecords
        .where()
        .sortByDateDesc()
        .findFirst();
    if (lastRecord == null) return true;
    
    return lastRecord.date.isBefore(currentDate());
  }

  // Методы для статистики
  static Future<double> getAverageSteps(String period) async {
    final now = tz.TZDateTime.now(tz.local);
    DateTime startDate;
    
    if (period == 'day') {
      startDate = now.subtract(Duration(days: 30));
    } else if (period == 'week') {
      startDate = now.subtract(Duration(days: 30 * 3));
    } else { // month
      startDate = now.subtract(Duration(days: 365));
    }
    
    final records = await getStepsForPeriod(startDate, now);
    if (records.isEmpty) return 0;
    
    final total = records.fold(0, (sum, record) => sum + record.steps);
    return total / records.length;
  }
}