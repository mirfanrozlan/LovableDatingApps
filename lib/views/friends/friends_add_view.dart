import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';

class FriendsAddView extends StatelessWidget {
  const FriendsAddView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      useGradient: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: controller, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or email')),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, child: const Text('Search'))),
            ]),
          ),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.group_add_outlined, size: 48),
                SizedBox(height: 8),
                Text('Add New Friends'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
