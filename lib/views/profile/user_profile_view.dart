import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/moments_controller.dart';
import '../../widgets/moments/moment_card.dart';
import '../../models/user_model.dart';
import '../../themes/theme.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});
  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late final MomentsController _controller;
  int? _userId;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      useGradient: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Container(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.loading && _controller.moments.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.error != null) {
                return Center(child: Text('Error: ${_controller.error}'));
              }
              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: CustomScrollView(
                  slivers: [
                    if (_controller.userProfile != null)
                      SliverToBoxAdapter(
                        child: _ProfileHeader(
                          user: _controller.userProfile!,
                          postsCount: _controller.moments.length,
                          totalLikes: _controller.moments.fold<int>(0, (sum, m) => sum + m.postLikes),
                        ),
                      ),
                    if (_controller.moments.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: Text('No posts yet')),
                      ),
                    if (_controller.moments.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final moment = _controller.moments[index];
                            return Column(
                              children: [
                                MomentCard(
                                  post: moment,
                                  onLike: () => _controller.likePost(moment.postId),
                                  onLoadComments: () => _controller.loadComments(moment.postId),
                                  onAddComment: (content, {parentId, replyId}) => _controller.addComment(
                                    moment.postId,
                                    content,
                                    parentId: parentId,
                                    replyId: replyId,
                                  ),
                                  onLikeComment: (id) => _controller.likeComment(id),
                                  onDeleteComment: (id) => _controller.deleteComment(id, moment.postId),
                                  onDeletePost: (postId) => _controller.deletePost(postId),
                                  currentUserId: _controller.currentUserId,
                                  flat: true,
                                  controller: _controller,
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                          childCount: _controller.moments.length,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final int postsCount;
  final int totalLikes;
  const _ProfileHeader({
    required this.user,
    required this.postsCount,
    required this.totalLikes,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppTheme.brandGradient,
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: user.media.isNotEmpty ? NetworkImage(user.media) : null,
                  child: user.media.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.age}, ${user.gender} • ${user.city}, ${user.country}',
                        style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (user.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ],
      ),
    );
  }
}
