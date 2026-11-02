import 'package:flutter/material.dart';

class AppTheme {
  // ---------- COLORS ----------

  static const Color darkBg = Color(0xFF000000);
  static const Color primaryRed = Color(0xFFE31E24);
  static const Color deepRed = Color(0xFF7B1113);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  // ---------- GRADIENT ----------

  static const LinearGradient redGradient = LinearGradient(
    colors: [primaryRed, deepRed],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // =====================================================
  // DARK THEME (Main Theme for TrustBus)
  // =====================================================

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryRed,

    colorScheme: const ColorScheme.dark(
      primary: primaryRed,
      secondary: deepRed,
      surface: surfaceDark,
    ),

    // ---------- APP BAR ----------

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // ---------- BUTTON ----------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),

    // ---------- CARD ----------

    cardTheme: CardThemeData(
      color: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // ---------- INPUT ----------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      hintStyle: const TextStyle(
        color: Colors.white38,
        fontSize: 14,
      ),
      prefixIconColor: Colors.white54,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: primaryRed,
          width: 1.5,
        ),
      ),
    ),
  );

  // =====================================================
  // LIGHT THEME (Optional)
  // =====================================================

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: primaryRed,
    colorScheme: const ColorScheme.light(
      primary: primaryRed,
      secondary: deepRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryRed,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
