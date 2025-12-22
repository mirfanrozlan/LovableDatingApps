import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/messages/messages_controller.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class MessagesListView extends StatefulWidget {
  const MessagesListView({super.key});

  @override
  State<MessagesListView> createState() => _MessagesListViewState();
}

class _MessagesListViewState extends State<MessagesListView> {
  late final MessagesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MessagesController();
    _controller.loadChats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: const [
                Text(
                  'Chats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Icon(Icons.search),
                SizedBox(width: 12),
                Icon(Icons.create),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    if (_controller.isLoading && _controller.chats.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_controller.error != null) {
                      return Center(child: Text('Error: ${_controller.error}'));
                    }

                    if (_controller.chats.isEmpty) {
                      return const Center(
                        child: Text(
                          'No chats yet. Find friends!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: _controller.chats.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = _controller.chats[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                                    ? NetworkImage(c.avatarUrl!)
                                    : null,
                            onBackgroundImageError: (exception, stackTrace) {
                              // Fallback
                            },
                            child:
                                c.avatarUrl == null || c.avatarUrl!.isEmpty
                                    ? Text(c.initials)
                                    : null,
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.time,
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                              if (c.unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${c.unread}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: c,
                              ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
