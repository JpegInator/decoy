// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, sort_child_properties_last, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'main_screen.dart';
import '../db/user_model.dart' as model;
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  final Isar isar;
  
  const AuthScreen({required this.isar});
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  bool _isRegistering = false;
  String? _errorMessage;

  void _toggleForm() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
    });
  }

    void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      if (_isRegistering) {
        // Проверяем существование пользователя в Isar
        final existingUser = await widget.isar.users
            .filter()
            .emailEqualTo(email)
            .findFirst();

        if (existingUser != null) {
          setState(() {
            _errorMessage = 'Пользователь с таким email уже существует';
          });
        } else {
          // Создаем нового пользователя в Isar
          final newUser = model.User(
            email: email,
            password: password,
            name: _nameController.text,
            age: int.parse(_ageController.text),
            weight: int.parse(_weightController.text),
            height: int.parse(_heightController.text),
          );

          await widget.isar.writeTxn(() async {
            await widget.isar.users.put(newUser);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Пользователь зарегистрирован!')),
          );
          _toggleForm();
        }
      } else {
        // Аутентификация через Isar
        final user = await widget.isar.users
            .filter()
            .emailEqualTo(email)
            .and()
            .passwordEqualTo(password)
            .findFirst();

        if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', user.id); // Сохраняем ID пользователя

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(isar: widget.isar, currentUser: user),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Неверный email или пароль');
      }
      }
    }
  }

  String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Введите email';
  }
  if (value.contains(' ')) {
    return 'Email не должен содержать пробелов';
  }
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$'
  );
  if (!emailRegex.hasMatch(value)) {
    return 'Введите корректный email';
  }
  return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    final RegExp passwordRegex = RegExp(
      r'^[A-Za-z0-9 !"#\$%&\()*+,-./:;<=>?@\[\\\]^_`{|}~]{8,16}$',
    );
    if (!passwordRegex.hasMatch(value)) {
      return 'Пароль должен содержать от 8 до 16 символов и состоять из латинских букв, цифр и специальных символов';
    }
    return null;
  }

  String? _validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Введите имя';
  }
  final RegExp nameRegex = RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$');
  if (!nameRegex.hasMatch(value)) {
    return 'Имя может содержать только буквы';
  }
  if (value.contains('  ')) {
    return 'Уберите лишние пробелы';
  }
  return null;
  }

  String? _validateAge(String? value) {
  if (value == null || value.isEmpty) {
    return 'Введите возраст';
  }
  final int? age = int.tryParse(value);
  if (age == null) {
    return 'Введите целое число';
  }
  if (age < 5 || age > 120) {
    return 'Введите реальный возраст (5-120)';
  }
  return null;
  }

  String? _validateWeight(String? value) {
  if (value == null || value.isEmpty) {
    return 'Введите вес';
  }
  final int? weight = int.tryParse(value);
  if (weight == null) {
    return 'Введите целое число (кг)';
  }
  if (weight < 20 || weight > 300) {
    return 'Введите реальный вес (20-300 кг)';
  }
  return null;
  }

  String? _validateHeight(String? value) {
  if (value == null || value.isEmpty) {
    return 'Введите рост';
  }
  final int? height = int.tryParse(value);
  if (height == null) {
    return 'Введите целое число (см)';
  }
  if (height < 50 || height > 250) {
    return 'Введите реальный рост (50-250 см)';
  }
  return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isRegistering ? 'Регистрация' : 'Авторизация'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', width: 24, height: 24),
            onPressed: () {
              if (_isRegistering) {
                _toggleForm();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Почта'),
                  validator: _validateEmail,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Пароль'),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                if (_isRegistering) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Имя'),
                    validator: _validateName,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(labelText: 'Возраст'),
                    validator: _validateAge,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Вес'),
                    validator: _validateWeight,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(labelText: 'Рост'),
                    validator: _validateHeight,
                  ),
                ],
                SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isRegistering ? 'Зарегистрироваться' : 'Войти'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _toggleForm,
                  child: Text(
                    _isRegistering ? 'Уже есть аккаунт?' : 'Нет аккаунта?',
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      )
    );
  }
}
class AuthManager {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
    await prefs.setInt(_keyUserId, userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
  }
}