import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/moments_controller.dart';
import '../../widgets/moments/moment_card.dart';
import '../../models/user_model.dart';
import 'settings_view.dart';

class MeView extends StatefulWidget {
  const MeView({super.key});

  @override
  State<MeView> createState() => _MeViewState();
}

class _MeViewState extends State<MeView> {
  late final MomentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MomentsController(type: MomentsType.me);
    _controller.loadMoments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      useGradient: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsView()),
                );
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
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
                        child: _ProfileHeader(user: _controller.userProfile!),
                      ),
                    if (_controller.moments.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: Text('No moments found')),
                      ),
                    if (_controller.moments.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final moment = _controller.moments[index];
                          return Column(
                            children: [
                              MomentCard(
                                post: moment,
                                onLike:
                                    () => _controller.likePost(moment.postId),
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
                                    (id) => _controller.likeComment(id),
                                onDeleteComment:
                                    (id) => _controller.deleteComment(
                                      id,
                                      moment.postId,
                                    ),
                                onDeletePost:
                                    (postId) => _controller.deletePost(postId),
                                currentUserId: _controller.currentUserId,
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }, childCount: _controller.moments.length),
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

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                user.media.isNotEmpty ? NetworkImage(user.media) : null,
            child:
                user.media.isEmpty
                    ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${user.age}, ${user.gender} • ${user.city}, ${user.country}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (user.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children:
                  user.interests.split(',').map((interest) {
                    final label = interest.trim();
                    if (label.isEmpty) return const SizedBox.shrink();
                    return Chip(
                      label: Text(label),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
        ],
      ),
    );
  }
}
