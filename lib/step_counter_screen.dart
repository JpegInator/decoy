import 'dart:async';
import 'package:provider/provider.dart';
import 'package:decoy/services/step_counter_service.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:isar/isar.dart';
import 'package:decoy/db/step_models.dart';
import 'package:decoy/services/isar_service.dart';
import 'package:decoy/services/goal_editor.dart';
import 'package:decoy/widgets/permission_handler_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:decoy/services/health_reminder_service.dart';
import 'package:decoy/app_theme.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:decoy/services/step_provider.dart';

class StepCounterScreen extends StatefulWidget {
  final Isar isar;
  final HealthReminderService healthReminderService;

  const StepCounterScreen({
    required this.isar,
    required this.healthReminderService,
    super.key,
    required StepCounterService stepCounterService,
  });

  @override
  StepCounterScreenState createState() => StepCounterScreenState();
}

class StepCounterScreenState extends State<StepCounterScreen> {
  int _steps = 0;
  int _dailyGoal = 10000;
  late Stream<StepCount> _stepCountStream;
  Timer? _dayCheckTimer;

  @override
  void initState() {
    super.initState();
    _initStepCounter();
  }

  Future<void> _initStepCounter() async {
    await _loadInitialData();
    await _checkDayChange();
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount);
    _startDayCheckTimer();
  }

  DateTime _currentDateInTimeZone() {
    return tz.TZDateTime.now(tz.getLocation('Asia/Yekaterinburg'));
  }

  DateTime _currentDateOnly() {
    final now = _currentDateInTimeZone();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _checkDayChange() async {
    final lastSavedDate = await _getLastSavedDate();
    final today = _currentDateOnly();

    if (lastSavedDate != null && lastSavedDate.isBefore(today)) {
      if (mounted) {
        setState(() => _steps = 0);
      }
      await _saveSteps(0);
    }
  }

  Future<DateTime?> _getLastSavedDate() async {
    final records =
        await widget.isar.stepRecords.where().sortByDateDesc().findFirst();
    return records?.date;
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    super.dispose();
  }

  void _startDayCheckTimer() {
    _dayCheckTimer?.cancel();
    final now = _currentDateInTimeZone();
    final nextMidnight = tz.TZDateTime(
      tz.getLocation('Asia/Yekaterinburg'),
      now.year,
      now.month,
      now.day + 1,
    );
    final initialDelay = nextMidnight.difference(now);

    Timer(initialDelay, () async {
      await _checkDayChange();
      _dayCheckTimer = Timer.periodic(const Duration(days: 1), (timer) async {
        await _checkDayChange();
      });
    });
  }

  Future<void> _loadInitialData() async {
    final settings = await IsarService.getSettings();
    if (mounted) {
      setState(() => _dailyGoal = settings.dailyGoal);
    }
    await _loadSteps();
  }

  Future<void> _loadSteps() async {
    final today = _currentDateOnly();
    final record = await widget.isar.stepRecords.where().dateEqualTo(today).findFirst();

    if (record != null) {
      if (mounted) {
        setState(() => _steps = record.steps);
      }
      // Обновляем провайдер
      final stepProvider = Provider.of<StepProvider>(context, listen: false);
      stepProvider.updateSteps(record.steps);
    } else if (_steps > 0) {
      if (mounted) {
        setState(() => _steps = 0);
      }
      await _saveSteps(0);
      // Обновляем провайдер
      final stepProvider = Provider.of<StepProvider>(context, listen: false);
      stepProvider.updateSteps(0);
    }
  }

  void _onStepCount(StepCount event) {
    _checkDayChange().then((_) {
      if (mounted) {
        setState(() => _steps = event.steps);
      }
      _saveSteps(event.steps);
      // Обновляем провайдер
      final stepProvider = Provider.of<StepProvider>(context, listen: false);
      stepProvider.updateSteps(event.steps);
    });
  }

  Future<void> _saveSteps(int steps) async {
    final today = _currentDateOnly();
    await widget.isar.writeTxn(() async {
      await widget.isar.stepRecords.put(
        StepRecord(
          date: today,
          steps: steps,
          goalAchieved: steps >= _dailyGoal,
        ),
      );
    });
  }

  Future<void> _updateGoal(int newGoal) async {
    if (mounted) {
      setState(() => _dailyGoal = newGoal);
    }
    final settings = await IsarService.getSettings();
    settings.dailyGoal = newGoal;
    await IsarService.updateSettings(settings);
    
    // Обновляем провайдер
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    stepProvider.updateDailyGoal(newGoal);
  }

  void _showGoalEditor(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Изменить цель'),
            content: GoalEditor(
              initialGoal: _dailyGoal,
              onGoalChanged: _updateGoal,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Градиент на весь экран
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.mainGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Прозрачность Scaffold
        appBar: AppBar(
          title: const Text('Шаги'),
          backgroundColor: Colors.transparent, // Прозрачный AppBar
          elevation: 0, // Убираем тень
        ),
        body: PermissionHandlerWidget(
          permission: Permission.activityRecognition,
          permissionType: 'доступа к датчикам шагов',
          icon: Icons.directions_walk,
          onPermissionDenied: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция шагомера ограничена без разрешений'),
                ),
              );
            }
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Текущие шаги
                Text(
                  '$_steps',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // Надпись "из"
                const Text(
                  'из',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                // Дневная цель
                Text(
                  '$_dailyGoal',
                  style: const TextStyle(fontSize: 32, color: Colors.black),
                ),
                const SizedBox(height: 40),
                // Кнопка изменения цели
                ElevatedButton(
                  onPressed: () => _showGoalEditor(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                  ),
                  child: const Text('Изменить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
