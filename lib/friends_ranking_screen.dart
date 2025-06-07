import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:decoy/services/step_provider.dart';

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
      appBar: AppBar(
        title: const Text('Рейтинг друзей'),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/add_friend.png',
              width: 24,
              height: 24,
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
              border: isCurrentUser
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Image.asset(
                'assets/images/profile.png',
                width: 24,
                height: 24,
              ),
              title: Text(user.name),
              trailing: Text('${user.steps} шагов'),
            ),
          );
        },
      ),
    );
  }
}