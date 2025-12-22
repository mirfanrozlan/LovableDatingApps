import 'package:flutter/material.dart';
import 'routes.dart';
import 'themes/theme.dart';
import 'controllers/app/theme_controller.dart';

void main() {
  runApp(const LoveConnectApp());
}

class LoveConnectApp extends StatelessWidget {
  const LoveConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        return MaterialApp(
          title: 'LoveConnect',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.login,
        );
      },
    );
  }
}
