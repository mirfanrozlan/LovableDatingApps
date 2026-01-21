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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1512), const Color(0xFF0A0F0D)]
                : [const Color(0xFFF0FDF8), const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            _buildDecorativeCircle(top: -50, right: -50, color: const Color(0xFF10B981), opacity: isDark ? 0.15 : 0.2),
            _buildDecorativeCircle(top: 200, left: -80, color: const Color(0xFF34D399), opacity: isDark ? 0.08 : 0.12),

            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header with search
                    _buildHeader(isDark),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
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
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                              }

                              if (items.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty ? 'No chats yet' : 'No results found',
                                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 80,
                                  endIndent: 20,
                                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                                ),
                                itemBuilder: (context, i) {
                                  final c = items[i];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                        backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                                            ? NetworkImage(c.avatarUrl!)
                                            : null,
                                        child: c.avatarUrl == null || c.avatarUrl!.isEmpty 
                                            ? Text(c.initials, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)) 
                                            : null,
                                      ),
                                    ),
                                    title: Text(
                                      c.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        c.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          c.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                                          ),
                                        ),
                                        if (c.unread > 0)
                                          Container(
                                            margin: const EdgeInsets.only(top: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${c.unread}',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _searchOpen
            ? Container(
                key: const ValueKey('search'),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: const Color(0xFF10B981), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        focusNode: _searchFocus,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search chats...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 20),
                      onPressed: () {
                        _search.clear();
                        setState(() => _searchOpen = false);
                      },
                    ),
                  ],
                ),
              )
            : Stack(
                key: const ValueKey('title'),
                alignment: Alignment.center,
                children: [
                  Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _searchOpen = true);
                        _searchFocus.requestFocus();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.search_rounded, color: const Color(0xFF10B981), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDecorativeCircle({
    required double top,
    double? right,
    double? left,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
