import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:isar/isar.dart';
import 'package:decoy/db/step_models.dart';
import 'package:decoy/services/isar_service.dart';
import 'services/goal_editor.dart';
import 'package:decoy/widgets/permission_handler_widget.dart';

class StepCounterScreen extends StatefulWidget {
  final Isar isar;

  const StepCounterScreen({required this.isar, super.key});

  @override
  StepCounterScreenState createState() => StepCounterScreenState();
}

class StepCounterScreenState extends State<StepCounterScreen> {
  int _steps = 0;
  int _dailyGoal = 10000; // Значение по умолчанию
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    _loadInitialData().then((_){
      if (mounted) {
      setState(() {});
        }
      }
    ); 
    _initStepCounter();
  }

  Future<void> _loadInitialData() async {
  final settings = await IsarService.getSettings();
  if (mounted) {
    setState(() => _dailyGoal = settings.dailyGoal);
    }
  }

  Future<void> _initStepCounter() async {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount);
    await _loadSteps();
  }

  Future<void> _loadSteps() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final record = await widget.isar.stepRecords
        .where()
        .dateEqualTo(todayDate)
        .findFirst();

    if (record != null) {
      setState(() => _steps = record.steps);
    }
  }

  void _onStepCount(StepCount event) {
    setState(() => _steps = event.steps);
    _saveSteps(event.steps);
  }

  Future<void> _saveSteps(int steps) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    await widget.isar.writeTxn(() async {
      await widget.isar.stepRecords.put(
        StepRecord(
          date: todayDate,
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
  }

  void _showGoalEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шагомер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showGoalEditor(context),
          ),
        ],
      ),
      body: PermissionHandlerWidget(
        permissionType: 'доступа к датчикам шагов',
        icon: Icons.directions_walk,
        onPermissionDenied: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функция шагомера ограничена без разрешений'),
            ),
          );
        },
        child: _buildStepCounterContent(),
      ),
    );
  }

  Widget _buildStepCounterContent() {
    final progress = _steps / _dailyGoal;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_steps / $_dailyGoal',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 20,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}