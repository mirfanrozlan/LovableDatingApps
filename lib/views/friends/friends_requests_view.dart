import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/friends_controller.dart';

class FriendsRequestsView extends StatelessWidget {
  FriendsRequestsView({super.key});
  final _controller = FriendsController();

  @override
  Widget build(BuildContext context) {
    final items = _controller.requests();
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      useGradient: false,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final r = items[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: CircleAvatar(child: Text(r.initials)),
              title: Text(r.from, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(r.text),
              trailing: Wrap(spacing: 6, children: [
                OutlinedButton(onPressed: () {}, child: const Text('Delete')),
                ElevatedButton(onPressed: () {}, child: const Text('Accept')),
              ]),
            ),
          );
        },
      ),
    );
  }
}
