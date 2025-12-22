import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/friends_controller.dart';
import '../../themes/theme.dart';

class FriendsSuggestionsView extends StatelessWidget {
  FriendsSuggestionsView({super.key});
  final _controller = FriendsController();

  @override
  Widget build(BuildContext context) {
    final items = _controller.youMayKnow();
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      useGradient: false,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = items[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                CircleAvatar(child: Text(p.initials)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(p.location),
                  Wrap(spacing: 6, children: p.interests.map((t) => _Chip(t)).toList()),
                  const SizedBox(height: 8),
                  Row(children: [
                    OutlinedButton(onPressed: () {}, child: const Text('Add')),
                    const SizedBox(width: 6),
                    OutlinedButton(onPressed: () {}, child: const Text('Mute')),
                    const SizedBox(width: 6),
                    ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary), child: const Text('Chat')),
                  ])
                ])),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String t;
  const _Chip(this.t);
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Text(t));
  }
}
