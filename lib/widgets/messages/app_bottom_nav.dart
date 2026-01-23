import 'package:flutter/material.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define theme-aware colors
    final backgroundColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6);
    final selectedColor = const Color(0xFF10B981);
    final unselectedColor =
        isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600;
    final selectedTextColor = isDark ? Colors.white : Colors.black87;
    final unselectedTextColor =
        isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: selectedTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              );
            }
            return TextStyle(
              color: unselectedTextColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: selectedColor, size: 24);
            }
            return IconThemeData(color: unselectedColor, size: 24);
          }),
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: selectedColor.withOpacity(isDark ? 0.2 : 0.15),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.explore_outlined,
                color: currentIndex == 0 ? selectedColor : unselectedColor,
              ),
              selectedIcon: Icon(Icons.explore, color: selectedColor),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: currentIndex == 1 ? selectedColor : unselectedColor,
              ),
              selectedIcon: Icon(Icons.chat_bubble, color: selectedColor),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.image_outlined,
                color: currentIndex == 2 ? selectedColor : unselectedColor,
              ),
              selectedIcon: Icon(Icons.image, color: selectedColor),
              label: 'Moments',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.favorite_border,
                color: currentIndex == 3 ? selectedColor : unselectedColor,
              ),
              selectedIcon: Icon(Icons.favorite, color: selectedColor),
              label: 'Friends',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: currentIndex == 4 ? selectedColor : unselectedColor,
              ),
              selectedIcon: Icon(Icons.person, color: selectedColor),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
