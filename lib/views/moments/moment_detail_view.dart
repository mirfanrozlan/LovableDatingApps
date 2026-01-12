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
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
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

  // Reuse logic from old MomentCard for building comment tree
  Widget _buildCommentList() {
    if (_loadingComments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No comments yet. Be the first to reply!',
            style: TextStyle(color: Colors.grey),
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
      children: roots.map((root) => _buildCommentNode(root, byParent)).toList(),
    );
  }

  Widget _buildCommentNode(
    CommentModel comment,
    Map<int, List<CommentModel>> byParent, {
    int depth = 0,
  }) {
    final children = byParent[comment.comsId] ?? [];
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: _buildCommentItem(comment),
        ),
        if (children.isNotEmpty)
          ...children.map(
            (child) => _buildCommentNode(child, byParent, depth: depth + 1),
          ),
      ],
    );
  }

  Future<void> _likeComment(CommentModel comment) async {
    // Optimistic update
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
      // Revert if failed
      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.comsId == comment.comsId);
          if (index != -1) {
            _comments[index] = comment;
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to like comment')));
      }
    }
  }

  Widget _buildCommentItem(CommentModel comment) {
    final isMyComment =
        widget.controller.currentUserId != null &&
        comment.publishId == widget.controller.currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    if (isMyComment)
                      GestureDetector(
                        onTap: () => _deleteComment(comment.comsId),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _startReply(comment),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        children: [
                          Icon(
                            comment.likedByMe
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color:
                                comment.likedByMe
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likes}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Moment',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use MomentCard but disable navigation to avoid recursion
                    MomentCard(
                      post: widget.post,
                      onLike:
                          () => widget.controller.likePost(
                            widget.post.postId,
                            widget.post.userId,
                          ),
                      onLoadComments: () async => [], // Not used here
                      onAddComment:
                          (_, {parentId, replyId}) async =>
                              null, // Not used here
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
                    ),
                    const Divider(height: 1),
                    _buildCommentList(),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 8,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingTo!.userName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelReply,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Post your reply...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _submitComment,
                        icon:
                            _submittingComment
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.send_rounded,
                                  color: Color(0xFF10B981),
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
