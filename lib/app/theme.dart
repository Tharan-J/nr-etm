import 'package:flutter/material.dart';

/// Utilitarian High-Contrast Visual Design System (Spec 09)
/// Designed for high outdoor readability, one-handed conductor ergonomics,
/// and instant operational feedback.
class AppTheme {
  static const Color primaryBg = Color(0xFF0F172A); // Dark slate background
  static const Color cardBg = Color(0xFF1E293B);    // Elevated slate container
  static const Color accentGreen = Color(0xFF22C55E); // Success / Captured state
  static const Color accentAmber = Color(0xFFF59E0B); // Syncing / Degraded status
  static const Color accentRed = Color(0xFFEF4444);   // Failure / Unauthorized alert
  static const Color textPrimary = Color(0xFFF8FAFC); // High-contrast white text
  static const Color textSecondary = Color(0xFF94A3B8); // Subtitle text

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: primaryBg,
      cardColor: cardBg,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: accentAmber,
        error: accentRed,
        surface: cardBg,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: primaryBg,
          minimumSize: const Size.fromHeight(52), // Minimum 48dp target (Spec 09)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
