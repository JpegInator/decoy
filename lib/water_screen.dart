import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:decoy/services/water_provider.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Учет воды')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Сколько воды вы выпили?',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Consumer<WaterProvider>(
              builder: (context, waterProvider, child) {
                return Text(
                  '${waterProvider.waterConsumed} мл',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(context, 100, '+100 мл'),
                _buildWaterButton(context, 250, '+250 мл'),
                _buildWaterButton(context, 500, '+500 мл'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showCustomInputDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
              ),
              child: const Text(
                'Другое',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Provider.of<WaterProvider>(context, listen: false).resetWater();
              },
              child: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(BuildContext context, int amount, String label) {
    return ElevatedButton(
      onPressed: () {
        Provider.of<WaterProvider>(context, listen: false).addWater(amount);
      },
      child: Text(label),
    );
  }

  void _showCustomInputDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить воду'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Количество в мл',
              hintText: 'Введите значение',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(textController.text);
                if (value != null && value > 0) {
                  Provider.of<WaterProvider>(context, listen: false).addWater(value);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пожалуйста, введите корректное число'),
                    ),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
}