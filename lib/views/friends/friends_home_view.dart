import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';
import '../../services/messages_service.dart';
import '../../models/messages/chat_invite_model.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../routes.dart';
import '../../models/user_model.dart';

class FriendsHomeView extends StatefulWidget {
  const FriendsHomeView({super.key});
  @override
  State<FriendsHomeView> createState() => _FriendsHomeViewState();
}

class _FriendsHomeViewState extends State<FriendsHomeView> {
  final _service = MessagesService();
  bool _loading = false;
  String? _error;
  List<ChatInviteModel> _invites = [];

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getInvites();
      setState(() {
        _invites = data.where((i) => i.friendStatus == 'accepted').toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openProfile(UserModel user) {
    Navigator.pushNamed(context, AppRoutes.userProfile, arguments: user.id);
  }

  void _startChat(UserModel user) {
    final chat = ChatSummaryModel(
      id: user.id.toString(),
      name: user.name,
      initials: user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
      avatarUrl: user.media,
      lastMessage: 'Say hi!',
      time: '',
      unread: 0,
    );
    Navigator.pushNamed(context, AppRoutes.chat, arguments: chat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a1a), const Color(0xFF0a0a0a)]
                : [const Color(0xFFF8FFFE), const Color(0xFFF0FDF8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: Text(
                    'Matches',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadInvites,
                  color: const Color(0xFF10B981),
                  child: CustomScrollView(
                    slivers: [
                      if (_loading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      
                      if (_error != null)
                        SliverFillRemaining(
                          child: Center(child: Text('Error: $_error')),
                        ),

                      if (!_loading && _error == null && _invites.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_outline_rounded,
                                  size: 64,
                                  color: const Color(0xFF10B981).withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No matches yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Keep discovering to find your perfect match!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (!_loading && _error == null && _invites.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverToBoxAdapter(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark 
                                        ? Colors.black.withOpacity(0.2)
                                        : const Color(0xFF10B981).withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: List.generate(_invites.length, (index) {
                                  final inv = _invites[index];
                                  final isLast = index == _invites.length - 1;
                                  
                                  return Column(
                                    children: [
                                      _MatchCard(
                                        user: inv.user,
                                        onViewProfile: () => _openProfile(inv.user),
                                        onChat: () => _startChat(inv.user),
                                        isDark: isDark,
                                      ),
                                      if (!isLast)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: isDark 
                                                ? Colors.white.withOpacity(0.06)
                                                : Colors.grey.shade100,
                                          ),
                                        ),
                                    ],
                                  );
                                }),
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
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onViewProfile;
  final VoidCallback onChat;
  final bool isDark;

  const _MatchCard({
    required this.user, 
    required this.onViewProfile, 
    required this.onChat,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewProfile,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with gradient border
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                      backgroundImage: user.media.isNotEmpty ? NetworkImage(user.media) : null,
                      child: user.media.isEmpty 
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ) 
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name, 
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.age} • ${user.city}, ${user.country}',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Icons instead of big buttons to save space
                  IconButton(
                    onPressed: onChat,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              if (user.interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.interests,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
