import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais - Paleta Azul Claro e Branco
  static const Color primaryColor = Color(
    0xFF03A9F4,
  ); // Light Blue 500 (Mais vibrante)
  static const Color primaryLight = Color(0xFFB3E5FC); // Light Blue 100
  static const Color primaryDark = Color(0xFF0288D1); // Light Blue 700

  static const Color backgroundColor = Color(
    0xFFF5F9FC,
  ); // Off-white azulado muito suave
  static const Color surfaceColor = Colors.white;

  static const Color textPrimary = Color(
    0xFF1A237E,
  ); // Azul escuro profundo para texto
  static const Color textSecondary = Color(0xFF757575);

  static const Color errorColor = Color(0xFFE53935);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Segoe UI', // Fonte padrão moderna do Windows/Flutter

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: primaryDark,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: primaryColor.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(20),
    ),

    useMaterial3: true,
  );
}
