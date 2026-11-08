import 'package:flutter/material.dart';

/// Design tokens derived from Google Stitch "Botanical Companion" Design System.
class BotanicalTheme {
  // Brand & Palette Colors
  static const Color canvas = Color(0xFFEDF6EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF013E37); // Deep Forest Evergreen
  static const Color onPrimary = Color(0xFFFFEFB3);
  static const Color butter = Color(0xFFFFEFB3); // Soft Creamy Butter
  static const Color butterLight = Color(0xFFFFFDF5);
  static const Color butterBorder = Color(0xFFE9D99C);
  static const Color sage = Color(0xFF4A7C59);
  static const Color textMain = Color(0xFF013E37);
  static const Color textMuted = Color(0xFF3D5A54);
  static const Color textLight = Color(0xFF627B75);
  static const Color outline = Color(0xFFDCE6DA);
  static const Color surfaceContainer = Color(0xFFEDF4EC);
  static const Color error = Color(0xFFBA1A1A);

  // Soft Ambient Diffuse Shadows (eliminates harsh borders)
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> floatingTrayShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Border Radii
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'sans-serif',
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: surface,
        secondary: butter,
        onSecondary: primary,
        surface: surface,
        onSurface: textMain,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

