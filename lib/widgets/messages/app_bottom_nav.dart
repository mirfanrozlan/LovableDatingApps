import 'package:flutter/material.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        if (i == 0) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.discover,
            (route) => false,
          );
        } else if (i == 1) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.messages,
            (route) => false,
          );
        } else if (i == 2) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.moments,
            (route) => false,
          );
        } else if (i == 3) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.friends,
            (route) => false,
          );
        } else if (i == 4) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.me,
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Coming soon')));
        }
      },
      indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.image_outlined),
          selectedIcon: Icon(Icons.image),
          label: 'Moments',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Friends',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Me',
        ),
      ],
    );
  }
}
