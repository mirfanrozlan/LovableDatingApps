import 'package:flutter/material.dart';
import '../../themes/theme.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final bool useGradient;
  const AppScaffold({super.key, required this.child, this.bottomNavigationBar, this.useGradient = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: isDark ? AppTheme.pageDecorationDark : AppTheme.pageDecoration,
        child: SafeArea(
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
