import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:decoy/services/step_provider.dart';
import 'package:decoy/app_theme.dart'; // Добавляем импорт для градиента

class User {
  final String name;
  final int steps;

  User(this.name, this.steps);
}

class FriendsRankingScreen extends StatelessWidget {
  const FriendsRankingScreen({super.key});

  List<User> generateUserList(BuildContext context) {
    final currentSteps = Provider.of<StepProvider>(context).steps;

    List<User> users = [
      User('Святозар', 2345),
      User('Добрыня', 9765),
      User('Василиса', 8373),
      User('Любава', 2827),
      User('Берислава', 6969),
      User('Вы', currentSteps),
    ];

    users.sort((a, b) => b.steps.compareTo(a.steps));
    return users;
  }

  @override
  Widget build(BuildContext context) {
    List<User> users = generateUserList(context);

    return Scaffold(
      body: Container(
        // Добавляем Container с градиентом
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.mainGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, // Делаем Scaffold прозрачным
          appBar: AppBar(
            title: const Text('Рейтинг друзей'),
            backgroundColor: Colors.transparent, // Прозрачный AppBar
            elevation: 0, // Убираем тень
            actions: [
              IconButton(
                icon: Image.asset(
                  'assets/images/add_friend.png',
                  width: 24,
                  height: 24,
                  color: Colors.black, // Черный цвет иконки для контраста
                ),
                onPressed: () {
                  // Добавить функционал добавления друга
                },
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrentUser = user.name == 'Вы';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.8,
                  ), // Полупрозрачный белый фон
                  border:
                      isCurrentUser
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Image.asset(
                    'assets/images/profile.png',
                    width: 24,
                    height: 24,
                    color: Colors.black, // Черный цвет иконки
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(color: Colors.black), // Черный текст
                  ),
                  trailing: Text(
                    '${user.steps} шагов',
                    style: const TextStyle(color: Colors.black), // Черный текст
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
