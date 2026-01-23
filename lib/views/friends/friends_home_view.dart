import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';
import '../../services/messages_service.dart';
import '../../services/discover_service.dart';
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
  final _discoverService = DiscoverService();
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
        _invites =
            data
                .where(
                  (i) =>
                      i.friendStatus == 'accepted' ||
                      i.friendStatus == 'pending' ||
                      i.friendStatus == 'blocked',
                )
                .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfile(UserModel user) {
    Navigator.pushNamed(context, AppRoutes.userProfile, arguments: user.id);
  }

  void _startChat(UserModel user) {
    final chat = ChatSummaryModel(
      id: user.id.toString(),
      name: user.name,
      initials:
          user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
      avatarUrl: user.media,
      lastMessage: 'Say hi!',
      time: '',
      unread: 0,
    );
    Navigator.pushNamed(context, AppRoutes.chat, arguments: chat);
  }

  Future<void> _respondInvite(ChatInviteModel invite, String response) async {
    int? inviteId = invite.inviteId;

    if (inviteId == null) {
      print(
        'FriendsHomeView._respondInvite: inviteId is null for user ${invite.user.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find invite information')),
        );
      }
      return;
    }

    // response should be 'accepted', 'rejected' or 'blocked'
    final result = await _discoverService.respondInvite(inviteId, response);
    if (result['success'] == true) {
      _loadInvites(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response == 'accepted'
                  ? 'Friend Accepted!'
                  : response == 'blocked'
                  ? 'User Blocked'
                  : 'Friend Rejected',
            ),
            backgroundColor:
                response == 'accepted'
                    ? const Color(0xFF10B981)
                    : Colors.redAccent,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Action failed')),
        );
      }
    }
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [const Color(0xFF0F1512), const Color(0xFF0A0F0D)]
                    : [
                      const Color(0xFFF0FDF8),
                      const Color(0xFFECFDF5),
                      const Color(0xFFD1FAE5),
                    ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            _buildDecorativeCircle(
              top: -50,
              right: -50,
              color: const Color(0xFF10B981),
              opacity: isDark ? 0.15 : 0.2,
            ),
            _buildDecorativeCircle(
              top: 200,
              left: -80,
              color: const Color(0xFF34D399),
              opacity: isDark ? 0.08 : 0.12,
            ),

            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(isDark),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadInvites,
                        color: const Color(0xFF10B981),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            if (_loading && _invites.isEmpty)
                              const SliverFillRemaining(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              )
                            else if (_error != null && _invites.isEmpty)
                              SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Error: $_error',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                        ),
                                        onPressed: _loadInvites,
                                        child: const Text(
                                          'Retry',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_invites.isEmpty)
                              SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.favorite_outline_rounded,
                                          size: 64,
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'No matches yet',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF064E3B),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Keep discovering to find your perfect match!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color:
                                            isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.white.withOpacity(0.5),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              isDark
                                                  ? Colors.black.withOpacity(
                                                    0.2,
                                                  )
                                                  : const Color(
                                                    0xFF10B981,
                                                  ).withOpacity(0.05),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: List.generate(_invites.length, (
                                        index,
                                      ) {
                                        final inv = _invites[index];
                                        final isLast =
                                            index == _invites.length - 1;

                                        return Column(
                                          children: [
                                            _MatchCard(
                                              user: inv.user,
                                              status: inv.friendStatus,
                                              onViewProfile:
                                                  () => _openProfile(inv.user),
                                              onChat:
                                                  () => _startChat(inv.user),
                                              onAccept:
                                                  () => _respondInvite(
                                                    inv,
                                                    'accepted',
                                                  ),
                                              onReject:
                                                  () => _respondInvite(
                                                    inv,
                                                    'rejected',
                                                  ),
                                              onBlock:
                                                  () => _respondInvite(
                                                    inv,
                                                    'blocked',
                                                  ),
                                              isDark: isDark,
                                            ),
                                            if (!isLast)
                                              Divider(
                                                height: 1,
                                                indent: 20,
                                                endIndent: 20,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                            .withOpacity(0.06)
                                                        : Colors.grey.shade100,
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Center(
        child: Text(
          'Friends',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF064E3B),
            letterSpacing: -0.5,
          ),
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

class _MatchCard extends StatelessWidget {
  final UserModel user;
  final String status;
  final VoidCallback onViewProfile;
  final VoidCallback onChat;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onBlock;
  final bool isDark;

  const _MatchCard({
    required this.user,
    required this.status,
    required this.onViewProfile,
    required this.onChat,
    this.onAccept,
    this.onReject,
    this.onBlock,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            (status == 'pending' || status == 'blocked')
                ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        status == 'pending'
                            ? 'Accept the request to view full profile.'
                            : 'Unblock the user to view full profile.',
                      ),
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: const Color(0xFF10B981),
                        onPressed: () {},
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                : onViewProfile,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar with gradient border
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors:
                        status == 'pending'
                            ? [Colors.orange.shade300, Colors.orange.shade200]
                            : status == 'blocked'
                            ? [Colors.grey.shade400, Colors.grey.shade300]
                            : [
                              const Color(0xFF10B981),
                              const Color(0xFF34D399),
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  backgroundImage:
                      user.media.isNotEmpty ? NetworkImage(user.media) : null,
                  child:
                      user.media.isEmpty
                          ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  status == 'pending'
                                      ? Colors.orange
                                      : status == 'blocked'
                                      ? Colors.grey
                                      : const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status == 'blocked')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Blocked',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.age} • ${user.city}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat Action Button
              if (status == 'pending')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onReject,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAccept,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (status == 'blocked')
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAccept, // Unblock (Accept)
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: Text(
                        'Unblock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Block Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBlock,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
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
