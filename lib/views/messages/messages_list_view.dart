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
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = MessagesController();
    _controller.loadChats();
    _search.addListener(() {
      setState(() {
        _searchQuery = _search.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF0a0a0a),
                  ]
                : [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFDCFCE7),
                  ],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_searchOpen)
                      Expanded(
                        child: Material(
                          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.search, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _search,
                                    focusNode: _searchFocus,
                                    decoration: const InputDecoration(
                                      hintText: 'Search chats',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _searchOpen = false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else 
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'Chats',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF064E3B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _searchOpen = true);
                                  _searchFocus.requestFocus();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Material(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final all = _controller.chats;
                        final items = _searchQuery.isEmpty
                            ? all
                            : all.where((c) {
                                final name = c.name.toLowerCase();
                                final last = c.lastMessage.toLowerCase();
                                return name.contains(_searchQuery) || last.contains(_searchQuery);
                              }).toList();

                        if (_controller.isLoading && items.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (_controller.error != null) {
                          return Center(child: Text('Error: ${_controller.error}'));
                        }

                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'No chats yet. Find friends!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB),
                          ),
                          itemBuilder: (context, i) {
                            final c = items[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                                        ? NetworkImage(c.avatarUrl!)
                                        : null,
                                child: c.avatarUrl == null || c.avatarUrl!.isEmpty ? Text(c.initials) : null,
                              ),
                              title: Text(
                                c.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
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
                                      color: isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (c.unread > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${c.unread}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: c),
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
        ),
      ),
    );
  }
}
