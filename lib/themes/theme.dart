import 'package:flutter/material.dart';

class AppTheme {
  // Global Color Constants
  // Change these values to affect the entire app
  static const Color primary = Color(0xFF21C26E);
  static const Color primaryDark = Color(0xFF119D53);
  static const Color backgroundLight = Color(0xFFF3FAF6);
  static const Color backgroundDark = Color(0xFF0F1A21);
  
  // Surface colors (used for cards, inputs, etc.)
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1F1F1F);

  // Success / Brand accent colors
  static const Color accent = Color(0xFF10B981);
  static const Color accentDark = Color(0xFF059669);

  // Dialog/Card Backgrounds (previously gradients)
  static const Color cardBgLight = Color(0xFFF0FDF4);
  static const Color cardBgDark = Color(0xFF1a1a1a);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          surface: surfaceLight,
          background: backgroundLight,
        ),
        scaffoldBackgroundColor: backgroundLight,
        fontFamily: 'Roboto',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: primary,
          surface: surfaceDark,
          background: backgroundDark,
        ),
        scaffoldBackgroundColor: backgroundDark,
        fontFamily: 'Roboto',
      );

  // Previously a gradient, now returns a solid color to remove gradients globally
  static BoxDecoration get pageDecoration => const BoxDecoration(
        color: backgroundLight,
      );

  // For dark mode page decoration
  static BoxDecoration get pageDecorationDark => const BoxDecoration(
        color: backgroundDark,
      );
}
