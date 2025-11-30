import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // A unique, sophisticated palette
  // Deep Ocean & Sand theme
  static const _primaryLight = Color(0xFF2D3142); // Dark Slate
  static const _primaryDark = Color(0xFFEAEAEA); // Off-white text for dark mode

  static const _bgLight = Color(0xFFF0F4F8); // Cool Gray/Blue tint
  static const _bgDark = Color(0xFF1C1E26); // Deep Blue-Black

  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _surfaceDark = Color(0xFF262A36);

  static const _accent = Color(0xFFEF8354); // Burnt Orange for interaction
  static const _secondary = Color(0xFF4F5D75); // Slate Blue

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.dmSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.dmSans(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _secondary,
        primary: _primaryLight,
        secondary: _secondary,
        tertiary: _accent,
        surface: _bgLight,
        onSurface: _primaryLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: _bgLight,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: _primaryLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceLight,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // More organic roundness
          side: BorderSide.none, // Cleaner look without borders
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: TextStyle(color: _secondary.withValues(alpha: 0.5)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _secondary,
        primary: _primaryDark,
        secondary: _secondary,
        tertiary: _accent,
        surface: _bgDark,
        onSurface: _primaryDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: _bgDark,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: _primaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceDark,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: TextStyle(color: _secondary.withValues(alpha: 0.5)),
      ),
    );
  }
}
