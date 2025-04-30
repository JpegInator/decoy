import 'dart:math';

import 'package:flutter/material.dart';

class GoalEditor extends StatelessWidget {
  final int initialGoal;
  final ValueChanged<int> onGoalChanged;

  const GoalEditor({
    super.key,
    required this.initialGoal,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialGoal.toString());
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Дневная цель',
              suffixText: 'шагов',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final newGoal = int.tryParse(value) ?? initialGoal;
              onGoalChanged(newGoal);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final newGoal = (int.tryParse(controller.text) ?? initialGoal) + 1000;
            controller.text = newGoal.toString();
            onGoalChanged(newGoal);
          },
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            final newGoal = max(1000, (int.tryParse(controller.text) ?? initialGoal) - 1000);
            controller.text = newGoal.toString();
            onGoalChanged(newGoal);
          },
        ),
      ],
    );
  }
}