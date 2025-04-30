// ignore_for_file: use_key_in_widget_constructors

import 'dart:math';
import 'package:flutter/material.dart';

class User {
  final String name;
  final int steps;

  User(this.name, this.steps);
}

List<User> generateUserList() {
  List<User> users = [
    User('Святозар', Random().nextInt(30000)),
    User('Добрыня', Random().nextInt(30000)),
    User('Василиса', Random().nextInt(30000)),
    User('Любава', Random().nextInt(30000)),
    User('Берислава', Random().nextInt(30000)),
    User('Вы', Random().nextInt(30000)),
  ];

  users.sort((a, b) => b.steps.compareTo(a.steps));
  return users;
}

class FriendsRankingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<User> users = generateUserList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Рейтинг друзей'),
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
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
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
