import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../routes.dart';

class FriendsHomeView extends StatelessWidget {
  const FriendsHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      useGradient: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Friends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _Item(title: 'Add Friend', onTap: () => Navigator.pushNamed(context, AppRoutes.friendsAdd)),
          _Item(title: 'People You May Know', onTap: () => Navigator.pushNamed(context, AppRoutes.friendsSuggestions)),
          _Item(title: 'People Nearby', onTap: () => Navigator.pushNamed(context, AppRoutes.friendsNearby)),
          _Item(title: 'Message Requests', onTap: () => Navigator.pushNamed(context, AppRoutes.friendsRequests)),
          _Item(title: 'People Match', onTap: () => Navigator.pushNamed(context, AppRoutes.friendsMatch)),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _Item({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}
