import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/moments_controller.dart';
import '../../widgets/moments/moment_card.dart';
import '../../models/user_model.dart';
import '../../themes/theme.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../routes.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});
  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> with SingleTickerProviderStateMixin {
  late final MomentsController _controller;
  int? _userId;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
                                      duration: const Duration(milliseconds: 800),
                                      vsync: this,
                                    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (_userId != id) {
      _userId = id;
      _controller = MomentsController(type: MomentsType.user, userId: _userId);
      _controller.loadMoments();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F1512),
                    const Color(0xFF0A0F0D),
                  ]
                : [
                    const Color(0xFFF0FDF8),
                    const Color(0xFFECFDF5),
                    const Color(0xFFD1FAE5),
                  ],
            stops: isDark ? null : const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF34D399).withOpacity(isDark ? 0.08 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.loading && _controller.moments.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                  }

                  if (_controller.error != null) {
                    return Center(child: Text('Error: ${_controller.error}'));
                  }

                  return RefreshIndicator(
                    onRefresh: _controller.refresh,
                    color: const Color(0xFF10B981),
                    child: CustomScrollView(
                      slivers: [
                        // Custom App Bar
                        SliverToBoxAdapter(
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_rounded,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Profile Header
                        if (_controller.userProfile != null)
                          SliverToBoxAdapter(
                            child: FadeTransition(
                              opacity: _animController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _animController,
                                  curve: Curves.easeOut,
                                )),
                                child: _ProfileHeader(
                                  user: _controller.userProfile!,
                                  postsCount: _controller.moments.length,
                                  totalLikes: _controller.moments.fold<int>(
                                    0,
                                    (sum, m) => sum + m.postLikes,
                                  ),
                                  interestsCount:
                                      _controller.userProfile!.interests
                                          .split(',')
                                          .where((e) => e.trim().isNotEmpty)
                                          .length,
                                  onMessage: () => _startChat(_controller.userProfile!),
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        
                        // Posts section header
                        if (_controller.moments.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.grid_view_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Moments',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_controller.moments.length}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Empty state
                        if (_controller.moments.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No moments yet',
                                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ),
                        
                        // Moments list
                        if (_controller.moments.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  children: List.generate(_controller.moments.length, (index) {
                                    final moment = _controller.moments[index];
                                    final isLast = index == _controller.moments.length - 1;
                                    
                                    return Column(
                                      children: [
                                        MomentCard(
                                          post: moment,
                                          onLike:
                                              () => _controller.likePost(
                                                moment.postId,
                                                moment.userId,
                                              ),
                                          onLoadComments:
                                              () =>
                                                  _controller.loadComments(moment.postId),
                                          onAddComment:
                                              (content, {parentId, replyId}) =>
                                                  _controller.addComment(
                                                    moment.postId,
                                                    content,
                                                    parentId: parentId,
                                                    replyId: replyId,
                                                  ),
                                          onLikeComment:
                                              (id, {publishId}) =>
                                                  _controller.likeComment(id, publishId),
                                          onDeleteComment:
                                              (id) => _controller.deleteComment(
                                                id,
                                                moment.postId,
                                              ),
                                          onDeletePost:
                                              (postId) => _controller.deletePost(postId),
                                          currentUserId: _controller.currentUserId,
                                          controller: _controller,
                                          flat: true,
                                          showDecoration: false,
                                        ),
                                        if (!isLast)
                                          Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: isDark 
                                                ? Colors.white.withOpacity(0.06)
                                                : Colors.grey.shade100,
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 30)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final int postsCount;
  final int totalLikes;
  final int interestsCount;
  final VoidCallback onMessage;
  final bool isDark;

  const _ProfileHeader({
    required this.user,
    required this.postsCount,
    required this.totalLikes,
    required this.interestsCount,
    required this.onMessage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xFF10B981).withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                          backgroundImage: user.media.isNotEmpty ? NetworkImage(user.media) : null,
                          child: user.media.isEmpty
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${user.age}',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${user.city}, ${user.country}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0FDF8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          value: '$postsCount',
                          label: 'Posts',
                          icon: Icons.grid_view_rounded,
                          isDark: isDark,
                        ),
                      ),
                      Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.grey.shade300),
                      Expanded(
                        child: _StatItem(
                          value: '$totalLikes',
                          label: 'Likes',
                          icon: Icons.favorite_rounded,
                          isDark: isDark,
                        ),
                      ),
                      Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.grey.shade300),
                      Expanded(
                        child: _StatItem(
                          value: '$interestsCount',
                          label: 'Interests',
                          icon: Icons.interests_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      user.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onMessage,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Message',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  const _StatItem({required this.label, required this.value, required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
        ),
      ],
    );
  }
}

