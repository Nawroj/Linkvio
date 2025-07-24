// app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF00b09b),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'SourceSansPro', // Your global font family setting
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00b09b),
      primary: const Color(0xFF00b09b),
      secondary: const Color(0xFF96c93d),
      background: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      iconTheme: IconThemeData(color: Color(0xFF00b09b)),
      elevation: 0,
      // 🥳 Add titleTextStyle to explicitly set font for AppBar titles
      titleTextStyle: TextStyle(
        fontFamily: 'SourceSansPro', // Ensure this matches your declared font family
        fontSize: 20, // Adjust size as needed
        fontWeight: FontWeight.w700, // Adjust weight as needed
        color: Colors.black, // Set title color
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF96c93d),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00b09b),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    useMaterial3: true,
  );

  // ⭐ NEW: Dark Theme Definition
  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF00b09b), // You can keep this or adjust for dark mode
    scaffoldBackgroundColor: Colors.grey[900], // Dark background
    fontFamily: 'SourceSansPro',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00b09b),
      primary: const Color(0xFF00b09b),
      secondary: const Color(0xFF96c93d),
      background: Colors.grey[900], // Dark background
      brightness: Brightness.dark, // Indicate this is a dark theme
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850], // Darker app bar
      iconTheme: const IconThemeData(color: Colors.white), // White icons
      elevation: 0,
      titleTextStyle: const TextStyle(
        fontFamily: 'SourceSansPro',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white, // White title text
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF96c93d), // Keep as is or adjust
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00b09b), // Keep as is or adjust
        foregroundColor: Colors.white, // White text on buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),
      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.white),
      headlineSmall: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
      labelLarge: TextStyle(color: Colors.white),
      labelMedium: TextStyle(color: Colors.white),
      labelSmall: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800], // Dark fill color for input fields
      labelStyle: TextStyle(color: Colors.white70), // Light label text
      hintStyle: TextStyle(color: Colors.white54), // Light hint text
      prefixIconColor: Colors.white70, // Light prefix icon color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00b09b), width: 2), // Keep accent for focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    ),
    cardColor: Colors.grey[850], // Dark card background
    useMaterial3: true,
  );
}