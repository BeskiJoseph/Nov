import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF0F2FA), // Light lilac background

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6B5AE0), // Main Purple
      secondary: Color(0xFF9485E9), // Lighter Purple
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.black,
    ),

    // 🔤 Text style
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'Inter', // Assumed or default
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        color: Colors.black87,
      ),
    ),

    // 🧾 Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, 
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1), // Added visible border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF6B5AE0),
          width: 1.5,
        ),
      ),
    ),

    // 🔘 Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B5AE0),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, 
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
