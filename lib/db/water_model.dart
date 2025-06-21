import 'package:isar/isar.dart';
import 'package:timezone/timezone.dart' as tz;

part 'water_model.g.dart';

@collection
class WaterRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // Дата записи (без времени)

  late int milliliters; // Количество воды в миллилитрах

  WaterRecord({
    this.id = Isar.autoIncrement,
    required this.date,
    required this.milliliters,
  });

  // Вспомогательный метод для получения текущей даты
  static DateTime currentDate() {
    final now = tz.TZDateTime.now(tz.local);
    return DateTime(now.year, now.month, now.day);
  }
}