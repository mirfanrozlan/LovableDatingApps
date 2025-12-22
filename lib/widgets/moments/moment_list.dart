import 'package:flutter/material.dart';
import '../../controllers/moments_controller.dart';
import 'moment_card.dart';

class MomentList extends StatelessWidget {
  final MomentsController controller;

  const MomentList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // We assume the controller is already being listened to by a parent widget or we listen here.
    // Ideally, the parent should rebuild when controller notifies, OR this widget should listen.
    // Since we are passing controller, let's wrap it in AnimatedBuilder or just assume parent handles it.
    // Better: use AnimatedBuilder here to listen to controller.

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.loading && controller.moments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return Center(child: Text('Error: ${controller.error}'));
        }

        if (controller.moments.isEmpty) {
          return const Center(child: Text('No moments found.'));
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.moments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder:
                (context, i) => MomentCard(
                  post: controller.moments[i],
                  onLike:
                      () => controller.likePost(controller.moments[i].postId),
                  onLoadComments:
                      () =>
                          controller.loadComments(controller.moments[i].postId),
                  onAddComment:
                      (content, {parentId, replyId}) => controller.addComment(
                        controller.moments[i].postId,
                        content,
                        parentId: parentId,
                        replyId: replyId,
                      ),
                  onLikeComment:
                      (commentId) => controller.likeComment(commentId),
                  onDeleteComment:
                      (commentId) => controller.deleteComment(
                        commentId,
                        controller.moments[i].postId,
                      ),
                  onDeletePost:
                      (postId) => controller.deletePost(postId),
                  currentUserId: controller.currentUserId,
                ),
          ),
        );
      },
    );
  }
}
