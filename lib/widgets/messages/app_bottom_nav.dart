import 'package:flutter/material.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              );
            }
            return const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            );
          },
        ),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: Color(0xFFF3F4F6),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            );
          }
        },
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
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
