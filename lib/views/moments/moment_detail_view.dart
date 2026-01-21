import 'package:flutter/material.dart';
import '../../models/moment_model.dart';
import '../../models/comment_model.dart';
import '../../themes/theme.dart';
import '../../widgets/moments/moment_card.dart';
import '../../controllers/moments_controller.dart';
import '../../widgets/common/app_scaffold.dart';

class MomentDetailView extends StatefulWidget {
  final MomentModel post;
  final MomentsController controller;

  const MomentDetailView({
    super.key,
    required this.post,
    required this.controller,
  });

  @override
  State<MomentDetailView> createState() => _MomentDetailViewState();
}

class _MomentDetailViewState extends State<MomentDetailView> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommentModel> _comments = [];
  bool _loadingComments = false;
  bool _submittingComment = false;
  CommentModel? _replyingTo;
  final Set<int> _expandedReplies = {}; // Track which comments have expanded replies

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _input.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (_loadingComments) return;
    setState(() => _loadingComments = true);
    try {
      final comments = await widget.controller.loadComments(widget.post.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingComments = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _input.text.trim();
    if (content.isEmpty || _submittingComment) return;

    setState(() => _submittingComment = true);
    try {
      int? parentId;
      int? replyId;
      if (_replyingTo != null) {
        parentId = _replyingTo!.comsId;
        replyId = _replyingTo!.publishId;
      }

      final newComment = await widget.controller.addComment(
        widget.post.postId,
        content,
        parentId: parentId,
        replyId: replyId,
      );

      if (newComment != null && mounted) {
        _input.clear();
        setState(() {
          // Auto-expand the parent comment's replies so the new reply is visible
          if (parentId != null) {
            _expandedReplies.add(parentId);
          }
          _replyingTo = null;
          _comments.add(newComment);
        });
        _focusNode.unfocus();
      }
    } finally {
      if (mounted) {
        setState(() => _submittingComment = false);
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Comment', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to delete this comment?'),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await widget.controller.deleteComment(
        commentId,
        widget.post.postId,
      );
      if (success && mounted) {
        setState(() {
          _comments.removeWhere((c) => c.comsId == commentId);
        });
      }
    }
  }

  void _startReply(CommentModel comment) {
    setState(() {
      _replyingTo = comment;
      _input.text = '@${comment.userName} ';
      _input.selection = TextSelection.fromPosition(
        TextPosition(offset: _input.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _input.clear();
    });
    _focusNode.unfocus();
  }

  Widget _buildCommentList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_loadingComments) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF10B981).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading comments...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: const Color(0xFF10B981).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to share your thoughts!',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Identify roots and group children
    final roots =
        _comments.where((c) => c.parentId == null || c.parentId == 0).toList();
    final allIds = _comments.map((c) => c.comsId).toSet();
    final orphans =
        _comments
            .where(
              (c) =>
                  c.parentId != null &&
                  c.parentId != 0 &&
                  !allIds.contains(c.parentId),
            )
            .toList();

    roots.addAll(orphans);

    final byParent = <int, List<CommentModel>>{};
    for (var c in _comments) {
      if (c.parentId != null &&
          c.parentId != 0 &&
          allIds.contains(c.parentId)) {
        byParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roots.map((root) => _buildCommentNode(root, byParent)).toList(),
    );
  }

  Widget _buildCommentNode(
    CommentModel comment,
    Map<int, List<CommentModel>> byParent, {
    int depth = 0,
    bool isLast = true,
  }) {
    final children = byParent[comment.comsId] ?? [];
    final isExpanded = _expandedReplies.contains(comment.comsId);
    
    // Count total replies (including nested)
    int countAllReplies(int parentId) {
      final direct = byParent[parentId] ?? [];
      int count = direct.length;
      for (var child in direct) {
        count += countAllReplies(child.comsId);
      }
      return count;
    }
    
    final totalReplies = countAllReplies(comment.comsId);
    
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: _buildCommentItem(
            comment, 
            depth > 0,
            replyCount: depth == 0 ? totalReplies : 0,
            isExpanded: isExpanded,
            onToggleReplies: depth == 0 && totalReplies > 0
                ? () {
                    setState(() {
                      if (isExpanded) {
                        _expandedReplies.remove(comment.comsId);
                      } else {
                        _expandedReplies.add(comment.comsId);
                      }
                    });
                  }
                : null,
          ),
        ),
        // Show replies if expanded (or always show for nested replies)
        if (children.isNotEmpty && (isExpanded || depth > 0))
          ...children.asMap().entries.map(
            (entry) => _buildCommentNode(
              entry.value, 
              byParent, 
              depth: depth + 1,
              isLast: entry.key == children.length - 1,
            ),
          ),
      ],
    );
  }

  Future<void> _likeComment(CommentModel comment) async {
    final wasLiked = comment.likedByMe;
    setState(() {
      final index = _comments.indexWhere((c) => c.comsId == comment.comsId);
      if (index != -1) {
        _comments[index] = comment.copyWith(
          likedByMe: !wasLiked,
          likes: comment.likes + (wasLiked ? -1 : 1),
        );
      }
    });

    try {
      await widget.controller.likeComment(comment.comsId, comment.publishId);
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.comsId == comment.comsId);
          if (index != -1) {
            _comments[index] = comment;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to like comment'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildCommentItem(
    CommentModel comment, 
    bool isReply, {
    int replyCount = 0,
    bool isExpanded = false,
    VoidCallback? onToggleReplies,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMyComment =
        widget.controller.currentUserId != null &&
        comment.publishId == widget.controller.currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isReply 
            ? (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAFA))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.shade200,
            width: 1,
          ),
          left: isReply 
              ? BorderSide(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 2,
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with profile picture - tappable to view user profile
              GestureDetector(
                onTap: () {
                  // Navigate to user profile (don't navigate to own profile)
                  if (comment.publishId != widget.controller.currentUserId) {
                    Navigator.pushNamed(
                      context,
                      '/user-profile',
                      arguments: comment.publishId,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: isReply ? 12 : 14,
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    backgroundImage: comment.userMedia.isNotEmpty 
                        ? NetworkImage(comment.userMedia) 
                        : null,
                    child: comment.userMedia.isEmpty
                        ? Text(
                            comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: isReply ? 10 : 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time row
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isReply ? 12 : 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade500, 
                            fontSize: isReply ? 10 : 11,
                          ),
                        ),
                        const Spacer(),
                        if (isMyComment)
                          GestureDetector(
                            onTap: () => _deleteComment(comment.comsId),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Comment content
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: isReply ? 13 : 14,
                        height: 1.4,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Actions row
                    Row(
                      children: [
                        // Reply button
                        GestureDetector(
                          onTap: () => _startReply(comment),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.reply_rounded,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Like button
                        GestureDetector(
                          onTap: () => _likeComment(comment),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                comment.likedByMe
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color: comment.likedByMe
                                    ? const Color(0xFF10B981)
                                    : Colors.grey.shade500,
                              ),
                              if (comment.likes > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: comment.likedByMe
                                        ? const Color(0xFF10B981)
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // View/Hide replies button (inside the same row)
                        if (onToggleReplies != null && replyCount > 0) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: onToggleReplies,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpanded 
                                      ? Icons.expand_less_rounded 
                                      : Icons.subdirectory_arrow_right_rounded,
                                  size: 14,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isExpanded 
                                      ? 'Hide' 
                                      : 'View $replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1512),
                    const Color(0xFF0A0F0D),
                  ]
                : [
                    const Color(0xFFF8FFFE),
                    const Color(0xFFF0FDF8),
                  ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'Moment',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark 
                                    ? Colors.black.withOpacity(0.3)
                                    : const Color(0xFF10B981).withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MomentCard(
                                post: widget.post,
                                onLike:
                                    () => widget.controller.likePost(
                                      widget.post.postId,
                                      widget.post.userId,
                                    ),
                                onLoadComments: () async => [],
                                onAddComment:
                                    (_, {parentId, replyId}) async => null,
                                onLikeComment: (_) async => null,
                                onDeleteComment: (_) async => false,
                                onDeletePost: (postId) async {
                                  final success = await widget.controller.deletePost(
                                    postId,
                                  );
                                  if (success && mounted) {
                                    Navigator.pop(context);
                                  }
                                  return success;
                                },
                                currentUserId: widget.controller.currentUserId,
                                isDetailView: true,
                                controller: widget.controller,
                                commentCount: _comments.length,
                                showDecoration: false,
                              ),
                              _buildCommentList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              // Comment input
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  top: 12,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyingTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Replying to ${_replyingTo!.userName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _cancelReply,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _input,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _submittingComment ? null : _submitComment,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: _submittingComment
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
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
      ),
    );
  }
}
