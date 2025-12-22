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

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (!controller.hasMore) return false;
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 100) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.moments.length +
                (controller.loading && controller.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i >= controller.moments.length &&
                  controller.loading &&
                  controller.hasMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return MomentCard(
                post: controller.moments[i],
                onLike: () => controller.likePost(controller.moments[i].postId),
                onLoadComments:
                    () => controller.loadComments(controller.moments[i].postId),
                onAddComment: (content, {parentId, replyId}) =>
                    controller.addComment(
                      controller.moments[i].postId,
                      content,
                      parentId: parentId,
                      replyId: replyId,
                    ),
                onLikeComment: (commentId) => controller.likeComment(commentId),
                onDeleteComment: (commentId) => controller.deleteComment(
                  commentId,
                  controller.moments[i].postId,
                ),
                onDeletePost: (postId) => controller.deletePost(postId),
                currentUserId: controller.currentUserId,
              );
            },
          ),
        );
      },
    );
  }
}
