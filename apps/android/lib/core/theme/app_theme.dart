import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette (High contrast, zero neon distractions)
  static const Color primaryBlue = Color(0xFF1E40AF); // Blue-800
  static const Color accentIndigo = Color(0xFF4338CA);
  static const Color profitEmerald = Color(0xFF047857); // Green-700
  static const Color lossCrimson = Color(0xFFB91C1C); // Red-700
  static const Color warningAmber = Color(0xFFD97706); // Amber-600

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentIndigo,
        error: lossCrimson,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate-50
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A), // Slate-900
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate-200
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50), // Minimum 48dp tap target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: const Color(0xFF60A5FA),
        error: const Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate-900
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B), // Slate-800
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
    );
  }
}
