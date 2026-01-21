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
  final int? commentCount;
  final bool showDecoration;

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
    this.commentCount,
    this.showDecoration = true,
  });


  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> with SingleTickerProviderStateMixin {
  bool _likedPostByMe = false;
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final success = await widget.onDeletePost(widget.post.postId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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

  void _handleLike() {
    setState(() => _likedPostByMe = !_likedPostByMe);
    if (_likedPostByMe) {
      _likeAnimController.forward().then((_) => _likeAnimController.reverse());
    }
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isDetailView ? null : _navigateToDetail,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: widget.isDetailView 
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isDetailView ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
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
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                          backgroundImage:
                              post.userMedia.isNotEmpty
                                  ? NetworkImage(post.userMedia)
                                  : null,
                          child: post.userMedia.isEmpty 
                              ? Text(
                                  post.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ) 
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.timeAgo,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // More options
                    if (widget.currentUserId != null && widget.currentUserId == post.userId)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _deletePost,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Content
                if (post.postCaption.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    post.postCaption,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    ),
                  ),
                ],
                
                // Image
                if (post.postMedia.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints: widget.isDetailView
                          ? const BoxConstraints()
                          : const BoxConstraints(maxHeight: 350),
                      child: Stack(
                        children: [
                          Image.network(
                            post.postMedia,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image unavailable',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Action Row
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF8FFFE),
                    borderRadius: widget.isDetailView
                        ? const BorderRadius.vertical(top: Radius.circular(14))
                        : BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Like button
                      Expanded(
                        child: _ActionButton(
                          icon: AnimatedBuilder(
                            animation: _likeScaleAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: _likeScaleAnimation.value,
                              child: Icon(
                                _likedPostByMe
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                size: 22,
                                color: _likedPostByMe
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ),
                          ),
                          label: '${post.postLikes + (_likedPostByMe ? 1 : 0)}',
                          isActive: _likedPostByMe,
                          onTap: _handleLike,
                          isDark: isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                      // Comment button
                      Expanded(
                        child: _ActionButton(
                          icon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 20,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                          label: '${widget.commentCount ?? post.commentsCount}',
                          isActive: false,
                          onTap: _navigateToDetail,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!widget.showDecoration) {
      return content;
    }

    return Container(
      margin: widget.flat ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: widget.flat || widget.isDetailView 
            ? BorderRadius.zero
            : BorderRadius.circular(20),
        boxShadow: widget.flat || widget.isDetailView ? null : [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white60 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
