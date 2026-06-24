import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors & Styling
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.red, // Main app color (like Snaptube)
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
  );

  // Dark Mode Colors & Styling
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.red,
    scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}