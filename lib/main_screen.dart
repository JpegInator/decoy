// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:decoy/user_profile.dart';
import 'package:decoy/step_counter_screen.dart';
import 'package:isar/isar.dart';
import 'package:decoy/db/user_model.dart' as model;
import 'package:decoy/widgets/permission_handler_widget.dart';
import 'package:decoy/services/step_counter_service.dart';
import 'package:decoy/deep_seek_chat.dart';
import 'package:decoy/water_screen.dart';

class MainScreen extends StatelessWidget {
  final Isar isar;
  final model.User currentUser;

  const MainScreen({required this.isar, required this.currentUser, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главный экран'),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/profile.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(isar: isar, currentUser: currentUser),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Привет, зай')),
      bottomNavigationBar: _buildBottomNavBar(context, isar),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, Isar isar) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равномерное распределение
          children: [
            // Кнопка шагомера
            IconButton(
              icon: Image.asset(
                'assets/images/walk_icon.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PermissionHandlerWidget(
                      permissionType: 'доступа к датчикам шагов',
                      icon: Icons.directions_walk,
                      onPermissionDenied: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Шагомер требует разрешений для работы',
                            ),
                          ),
                        );
                      },
                      child: StepCounterScreen(isar: isar, stepCounterService: StepCounterService()),
                    ),
                  ),
                );
              },
            ),
            
            // Кнопка чата с DeepSeek
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              iconSize: 28,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(), // Ваш экран чата
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.local_drink),
              iconSize: 28,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaterScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}