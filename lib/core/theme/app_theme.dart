import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF), // Roxo suave infantil
      brightness: Brightness.light,
    ),
    fontFamily: 'Nunito', // Recomendado adicionar no pubspec
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF),
      brightness: Brightness.dark,
    ),
  );

  // Tema Preto e Branco / Alto Contraste
  static ThemeData get highContrastTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.highContrastLight(
      primary: Colors.black,
      secondary: Colors.black87,
      surface: Colors.white,
    ),
  );
}
