import 'package:decoy/db/water_model.dart';
import 'package:isar/isar.dart';

class WaterService {
  static late Isar _isar;

  static Future<void> init(Isar isar) async {
    _isar = isar;
  }

  // Сохранение записи о воде за сегодня
  static Future<void> saveWater(int milliliters) async {
    final today = WaterRecord.currentDate();
    final existingRecord = await _isar.waterRecords
        .filter()
        .dateEqualTo(today)
        .findFirst();

    if (existingRecord != null) {
      existingRecord.milliliters += milliliters;
      await _isar.writeTxn(() async {
        await _isar.waterRecords.put(existingRecord);
      });
    } else {
      final record = WaterRecord(
        date: today,
        milliliters: milliliters,
      );
      await _isar.writeTxn(() async {
        await _isar.waterRecords.put(record);
      });
    }
  }

  // Получение записи о воде за сегодня
  static Future<int> getTodayWater() async {
    final record = await _isar.waterRecords
        .filter()
        .dateEqualTo(WaterRecord.currentDate())
        .findFirst();
    return record?.milliliters ?? 0;
  }

  // Сброс воды за сегодня
  static Future<void> resetTodayWater() async {
    final today = WaterRecord.currentDate();
    final existingRecord = await _isar.waterRecords
        .filter()
        .dateEqualTo(today)
        .findFirst();

    if (existingRecord != null) {
      await _isar.writeTxn(() async {
        await _isar.waterRecords.delete(existingRecord.id);
      });
    }
  }
}