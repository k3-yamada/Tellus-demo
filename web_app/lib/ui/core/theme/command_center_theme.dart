import 'package:flutter/material.dart';

class CommandCenterTheme {
  static const background = Color(0xFF0B1220);
  static const panel = Color(0xFF141E2E);
  static const border = Color(0xFF2A3A52);
  static const accent = Color(0xFF2DD4BF);
  static const accentWarm = Color(0xFFF59E0B);
  static const dataDemo = Color(0xFF9B8CFF);
  static const textPrimary = Color(0xFFE8F0FA);
  static const textMuted = Color(0xFF8BA3BC);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accentWarm,
        surface: panel,
      ),
      cardTheme: CardThemeData(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
