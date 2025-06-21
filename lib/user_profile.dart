import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'auth_screen.dart';
import 'friends_ranking_screen.dart';
import 'db/user_model.dart' as model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decoy/app_theme.dart'; // Добавляем импорт для градиента

class ProfileScreen extends StatelessWidget {
  final Isar isar;
  final model.User currentUser;

  const ProfileScreen({
    super.key,
    required this.isar,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Профиль пользователя'),
            backgroundColor: Colors.transparent, // Прозрачный AppBar
            elevation: 0, // Убираем тень
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildUserProfile(context),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              await prefs.remove('userId');

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen(isar: isar)),
              );
            },
            child: Image.asset(
              'assets/images/exit_from_account.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return ListView(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ListTile(
            leading: Image.asset(
              'assets/images/personal_info.png',
              width: 24,
              height: 24,
            ),
            title: const Text('Личные данные'),
            onTap: () {
              _showUserDetails(context);
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ListTile(
            leading: Image.asset(
              'assets/images/friends.png',
              width: 24,
              height: 24,
            ),
            title: const Text('Друзья'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendsRankingScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ListTile(
            leading: Image.asset(
              'assets/images/change_password.png',
              width: 24,
              height: 24,
            ),
            title: const Text('Изменить пароль'),
            onTap: () {
              _changePassword(context);
            },
          ),
        ),
      ],
    );
  }

  void _showUserDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Личные данные'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Имя: ${currentUser.name}'),
              Text('Почта: ${currentUser.email}'),
              Text('Возраст: ${currentUser.age}'),
              Text('Вес: ${currentUser.weight} кг'),
              Text('Рост: ${currentUser.height} см'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            TextButton(
              onPressed: () => _editProfile(context),
              child: const Text('Редактировать'),
            ),
          ],
        );
      },
    );
  }

  void _editProfile(BuildContext context) {
    final nameController = TextEditingController(text: currentUser.name);
    final ageController = TextEditingController(
      text: currentUser.age.toString(),
    );
    final weightController = TextEditingController(
      text: currentUser.weight.toString(),
    );
    final heightController = TextEditingController(
      text: currentUser.height.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать профиль'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Возраст'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Вес'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: 'Рост'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final updatedUser =
                    currentUser
                      ..name = nameController.text
                      ..age = int.parse(ageController.text)
                      ..weight = int.parse(weightController.text)
                      ..height = int.parse(heightController.text);

                await isar.writeTxn(() async {
                  await isar.users.put(updatedUser);
                });

                Navigator.pop(context);
                _showUserDetails(context); // Обновляем данные
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _changePassword(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Смена пароля'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                obscureText: true,
              ),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Подтвердите пароль',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пароли не совпадают')),
                  );
                  return;
                }

                final updatedUser =
                    currentUser..password = passwordController.text;

                await isar.writeTxn(() async {
                  await isar.users.put(updatedUser);
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пароль успешно изменен')),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}
