import 'package:flutter/material.dart';
import '../../controllers/moments_controller.dart';
import 'moment_card.dart';

class MomentList extends StatelessWidget {
  final MomentsController controller;

  const MomentList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.loading && controller.moments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading moments...',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.moments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.15),
                          const Color(0xFF34D399).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: const Color(0xFF10B981).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No moments yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share a moment!\nTap the + button to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: const Color(0xFF10B981),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (!controller.hasMore) return false;
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 100) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount:
                  controller.moments.length +
                  (controller.loading && controller.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= controller.moments.length &&
                    controller.loading &&
                    controller.hasMore) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF10B981).withOpacity(0.6),
                        ),
                      ),
                    ),
                  );
                }
                
                final isFirst = i == 0;
                final isLast = i == controller.moments.length - 1;

                return Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: isFirst ? const Radius.circular(20) : Radius.zero,
                          bottom: isLast ? const Radius.circular(20) : Radius.zero,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MomentCard(
                        post: controller.moments[i],
                        onLike:
                            () => controller.likePost(
                              controller.moments[i].postId,
                              controller.moments[i].userId,
                            ),
                        onLoadComments:
                            () => controller.loadComments(controller.moments[i].postId),
                        onAddComment:
                            (content, {parentId, replyId}) => controller.addComment(
                              controller.moments[i].postId,
                              content,
                              parentId: parentId,
                              replyId: replyId,
                            ),
                        onLikeComment:
                            (commentId, {parentId}) =>
                                controller.likeComment(commentId, parentId),
                        onDeleteComment:
                            (commentId) => controller.deleteComment(
                              commentId,
                              controller.moments[i].postId,
                            ),
                        onDeletePost: (postId) => controller.deletePost(postId),
                        currentUserId: controller.currentUserId,
                        controller: controller,
                        flat: true,
                        showDecoration: false,
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
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
              },
            ),
          ),
        );
      },
    );
  }
}
