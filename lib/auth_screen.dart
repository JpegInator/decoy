import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:decoy/app_theme.dart';
import 'package:decoy/main_screen.dart';
import 'package:decoy/db/user_model.dart' as model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decoy/services/step_counter_service.dart';
import 'package:decoy/services/health_reminder_service.dart';
import 'package:decoy/services/water_provider.dart';
import 'package:decoy/services/step_provider.dart';

class AuthScreen extends StatefulWidget {
  final Isar isar;
  const AuthScreen({required this.isar, Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final StepCounterService _stepCounterService = StepCounterService();
  final WaterProvider _waterProvider = WaterProvider();
  final StepProvider _stepProvider = StepProvider();
  late final HealthReminderService _healthReminderService;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _toggleForm() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      if (_isRegistering) {
        await _registerUser(email, password);
      } else {
        await _loginUser(email, password);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerUser(String email, String password) async {
    final existingUser =
        await widget.isar.users.filter().emailEqualTo(email).findFirst();

    if (existingUser != null) {
      throw Exception('Пользователь с таким email уже существует');
    }

    final newUser = model.User(
      email: email,
      password: password,
      name: _nameController.text,
      age: int.parse(_ageController.text),
      weight: int.parse(_weightController.text),
      height: int.parse(_heightController.text),
    );

    await widget.isar.writeTxn(() => widget.isar.users.put(newUser));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Регистрация успешна!')));
    _toggleForm();
  }

  Future<void> _loginUser(String email, String password) async {
    final user =
        await widget.isar.users
            .filter()
            .emailEqualTo(email)
            .and()
            .passwordEqualTo(password)
            .findFirst();

    if (user == null) {
      throw Exception('Неверный email или пароль');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('userId', user.id);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(isar: widget.isar, currentUser: user, stepCounterService: _stepCounterService,
      healthReminderService: _healthReminderService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.mainGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/group_one.png', height: 80),
                      const SizedBox(height: 40),
                      Text(
                        _isRegistering ? 'Регистрация' : 'Вход',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildAuthForm(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.errorRed),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const SizedBox(height: 80),
                      Center(child: _buildAuthButton()),
                      const SizedBox(height: 16),
                      Center(child: _buildToggleFormButton()),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Почта',
          validator: _validateEmail,
          icon: Icons.email,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Пароль',
          validator: _validatePassword,
          icon: Icons.lock,
          isPassword: true,
        ),
        if (_isRegistering) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Имя',
            validator: _validateName,
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ageController,
            label: 'Возраст',
            validator: _validateAge,
            icon: Icons.cake,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _weightController,
            label: 'Вес (кг)',
            validator: _validateWeight,
            icon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _heightController,
            label: 'Рост (см)',
            validator: _validateHeight,
            icon: Icons.height,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.textFieldFill,
        prefixIcon: Icon(icon, color: Colors.black.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: AppColors.errorRed),
      ),
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                  _isRegistering ? 'Зарегистрироваться' : 'Войти',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
      ),
    );
  }

  Widget _buildToggleFormButton() {
    return TextButton(
      onPressed: _isLoading ? null : _toggleForm,
      child: Text(
        _isRegistering
            ? 'Уже есть аккаунт? Войти'
            : 'Нет аккаунта? Зарегистрироваться',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  // Валидаторы
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Введите email';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Пароль должен быть не менее 6 символов';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Введите имя';
    if (value.length < 2) return 'Имя слишком короткое';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Введите возраст';
    final age = int.tryParse(value);
    if (age == null || age < 5 || age > 120) return 'Введите реальный возраст';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Введите вес';
    final weight = int.tryParse(value);
    if (weight == null || weight < 20 || weight > 300)
      return 'Недопустимый вес';
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return 'Введите рост';
    final height = int.tryParse(value);
    if (height == null || height < 50 || height > 250)
      return 'Недопустимый рост';
    return null;
  }

  @override
  void dispose() {
    _stepCounterService.dispose();
    _healthReminderService.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _stepCounterService.init();
    _healthReminderService = HealthReminderService(_waterProvider, _stepProvider, widget.isar);
    _healthReminderService.init();
  }
}
