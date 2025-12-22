import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF21C26E);
  static const Color primaryDark = Color(0xFF119D53);
  static const Color backgroundLight = Color(0xFFF3FAF6);
  static const Color backgroundDark = Color(0xFF0F1A21);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundLight,
        fontFamily: 'Roboto',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: backgroundDark,
        fontFamily: 'Roboto',
      );

  static LinearGradient get brandGradient => const LinearGradient(
        colors: [Color(0xFFC8F5E4), Color(0xFFF3FAF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
