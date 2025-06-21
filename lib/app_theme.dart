import 'package:flutter/material.dart';

class AppColors {
  // Основные цвета
  static const primaryGreen = Color(0xFF61FF83);
  static const primaryYellow = Color(0xFFEFFD2F);
  static const primaryBlue = Color(0xFF4598FC);
  static const darkBlue = Color(0xFF3044F2);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // Градиенты
  static const mainGradient = [primaryGreen, primaryYellow];
  static const blueGradient = [primaryBlue, darkBlue];

  // Фоновые цвета
  static const scaffoldBackground = white;
  static const textFieldFill = Color(0xFFF9F9F9);

  // Элементы интерфейса
  static const chatUserBubble = Color(0xFFF1F9FF);
  static const chatAiBubble = Color(0xFFEFF4FF);
  static const progressBackground = Color(0xFFD7E6FD);
  static const errorRed = Color(0xFFD32F2F);
}

final appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.primaryBlue,
    surface: AppColors.white,
    background: AppColors.scaffoldBackground,
    error: AppColors.errorRed,
  ),

  // Текстовые стили с учетом всех вариантов Inter
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900, // Inter-Black
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700, // Inter-Bold
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600, // Inter-SemiBold
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500, // Inter-Medium
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400, // Inter-Regular
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400, // Inter-Regular
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400, // Inter-Regular
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500, // Inter-Medium
      letterSpacing: 0.5,
    ),
  ),

  // AppBar
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600, // Inter-SemiBold
      color: Colors.black,
    ),
    iconTheme: IconThemeData(color: Colors.black),
  ),

  // Кнопки
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w500, // Inter-Medium
      ),
    ),
  ),

  // Поля ввода
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.textFieldFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(
      fontWeight: FontWeight.w400, // Inter-Regular
      color: Colors.black.withOpacity(0.6),
    ),
  ),

  // Карточки
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    margin: EdgeInsets.zero,
    color: AppColors.white,
  ),

  // Progress indicators
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    circularTrackColor: AppColors.progressBackground,
    color: AppColors.primaryBlue,
  ),
);
