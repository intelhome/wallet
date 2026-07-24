import 'package:flutter/material.dart';

class AppTheme {
  // =========================================
  // COLORES MODO OSCURO (TTC Gasless System)
  // =========================================
  static const Color _darkPrimary = Color(0xFF4361EE);
  static const Color _darkSecondary = Color(0xFF7209B7);
  static const Color _darkTertiary = Color(0xFFFF9F1C);
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkText = Color(0xFFDAE2FD);

  // =========================================
  // COLORES MODO CLARO (Claro System)
  // =========================================
  static const Color _lightPrimary = Color(0xFF0052FF);
  static const Color _lightSecondary = Color(0xFF525F73);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFF9FAFB);
  static const Color _lightText = Color(0xFF101828);

  static ThemeData get lightTheme {
    return ThemeData.light(useMaterial3: true).copyWith(
      primaryColor: _lightPrimary,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightSurface,
      // Tipografía institucional en modo claro
      textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Roboto'),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _lightText),
        titleTextStyle: TextStyle(color: _lightText, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      ),
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        onSurface: _lightText,
        error: Color(0xFFBA1A1A),
      ),
      iconTheme: const IconThemeData(color: _lightText),
      dividerColor: _lightText.withOpacity(0.1),
      cardTheme: const CardThemeData(
        color: _lightSurface,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkSurface,
      // Tipografía nativa cripto en modo oscuro
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkText),
        titleTextStyle: TextStyle(color: _darkText, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      ),
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        tertiary: _darkTertiary,
        surface: _darkSurface,
        onSurface: _darkText,
        error: Color(0xFFFFB4AB),
      ),
      iconTheme: const IconThemeData(color: _darkText),
      dividerColor: _darkText.withOpacity(0.1),
      cardTheme: const CardThemeData(
        color: _darkSurface,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
      ),
    );
  }
}