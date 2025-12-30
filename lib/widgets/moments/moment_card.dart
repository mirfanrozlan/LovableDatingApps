import 'package:flutter/material.dart';
import '../../models/moment_model.dart';
import '../../models/comment_model.dart';
import '../../themes/theme.dart';
import '../../controllers/moments_controller.dart';
import '../../views/moments/moment_detail_view.dart';

class MomentCard extends StatefulWidget {
  final MomentModel post;
  final VoidCallback onLike;
  final Future<List<CommentModel>> Function() onLoadComments;
  final Future<CommentModel?> Function(String, {int? parentId, int? replyId})
  onAddComment;
  final Future<CommentModel?> Function(int) onLikeComment;
  final Future<bool> Function(int) onDeleteComment;
  final Future<bool> Function(int) onDeletePost;
  final int? currentUserId;
  final bool flat;
  final bool isDetailView;
  final MomentsController? controller;

  const MomentCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onLoadComments,
    required this.onAddComment,
    required this.onLikeComment,
    required this.onDeleteComment,
    required this.onDeletePost,
    this.currentUserId,
    this.flat = false,
    this.isDetailView = false,
    this.controller,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  bool _likedPostByMe = false;

  @override
  void initState() {
    super.initState();
    // Initialize liked state if available in model (model doesn't have likedByMe yet, assuming handled by parent or local toggle)
    // The current model doesn't seem to have 'likedByMe'. The old code managed it locally via `_likedPostByMe`.
    // We'll stick to local toggle for immediate feedback.
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final success = await widget.onDeletePost(widget.post.postId);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    }
  }

  void _navigateToDetail() {
    if (widget.isDetailView || widget.controller == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MomentDetailView(
              post: widget.post,
              controller: widget.controller!,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return InkWell(
      onTap: _navigateToDetail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              widget.flat
                  ? null
                  : Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Avatar
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      post.userMedia.isNotEmpty
                          ? NetworkImage(post.userMedia)
                          : null,
                  child: post.userMedia.isEmpty ? Text(post.initials) : null,
                ),
                // Could add a vertical line here if it was a thread chain
              ],
            ),
            const SizedBox(width: 12),
            // Right Column: Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Name, Time, More
                  Row(
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (widget.currentUserId != null &&
                          widget.currentUserId == post.userId)
                        GestureDetector(
                          onTap: _deletePost,
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Content Text
                  if (post.postCaption.isNotEmpty)
                    Text(
                      post.postCaption,
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),
                  // Content Image
                  if (post.postMedia.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints:
                            widget.isDetailView
                                ? const BoxConstraints()
                                : const BoxConstraints(maxHeight: 300),
                        child: Image.network(
                          post.postMedia,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder:
                              (ctx, err, stack) => Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Action Row
                  Row(
                    children: [
                      // Like
                      GestureDetector(
                        onTap: () {
                          setState(() => _likedPostByMe = !_likedPostByMe);
                          widget.onLike();
                        },
                        child: Row(
                          children: [
                            Icon(
                              _likedPostByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color:
                                  _likedPostByMe
                                      ? const Color(0xFF10B981)
                                      : Colors.black54,
                            ),
                            if (post.postLikes > 0 || _likedPostByMe) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${post.postLikes + (_likedPostByMe ? 1 : 0)}', // Basic optimistic update visualization
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Comment
                      GestureDetector(
                        onTap: _navigateToDetail,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: Colors.black54,
                            ),
                            if (post.commentsCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${post.commentsCount}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
