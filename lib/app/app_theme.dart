import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Крупные зоны нажатия и читабельные шрифты для планшетов 6–7 лет.
abstract final class AppTheme {
  static const double minTouchTarget = 56;
  static const double cellMinSize = 72;

  static const _seed = Color(0xFF2A9D8F);
  static const _surface = Color(0xFFF7FAF9);

  static ThemeData light({double fontScale = 1.0}) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.light,
        surface: _surface,
      ),
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final nunito = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFF1A2E2A),
      displayColor: const Color(0xFF1A2E2A),
    );

    final scaled = nunito.copyWith(
      headlineMedium: nunito.headlineMedium?.copyWith(
        fontSize: 28 * fontScale,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      headlineSmall: nunito.headlineSmall?.copyWith(
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: nunito.titleLarge?.copyWith(
        fontSize: 22 * fontScale,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: nunito.titleMedium?.copyWith(
        fontSize: 18 * fontScale,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: nunito.bodyLarge?.copyWith(
        fontSize: 18 * fontScale,
        height: 1.45,
      ),
      bodyMedium: nunito.bodyMedium?.copyWith(
        fontSize: 16 * fontScale,
        height: 1.4,
      ),
      labelLarge: nunito.labelLarge?.copyWith(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _surface,
      textTheme: scaled,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _surface,
        foregroundColor: const Color(0xFF1A2E2A),
        titleTextStyle: scaled.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: base.colorScheme.outline.withValues(alpha: 0.35)),
        ),
        color: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: scaled.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        borderRadius: BorderRadius.circular(8),
        color: base.colorScheme.primary,
      ),
    );
  }
}
