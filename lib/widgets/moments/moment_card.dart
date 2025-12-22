import 'package:flutter/material.dart';
import '../../models/moment_model.dart';
import '../../models/comment_model.dart';

class MomentCard extends StatefulWidget {
  final MomentModel post;
  final VoidCallback onLike;
  final Future<List<CommentModel>> Function() onLoadComments;
  final Future<CommentModel?> Function(String, {int? parentId, int? replyId})
  onAddComment;
  final Future<CommentModel?> Function(int) onLikeComment;
  final Future<bool> Function(int) onDeleteComment;
  final int? currentUserId;

  const MomentCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onLoadComments,
    required this.onAddComment,
    required this.onLikeComment,
    required this.onDeleteComment,
    this.currentUserId,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  bool _showComments = false;
  final _input = TextEditingController();
  final _focusNode = FocusNode();
  List<CommentModel> _comments = [];
  bool _loadingComments = false;
  bool _submittingComment = false;
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _input.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
    if (_showComments && _comments.isEmpty) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    if (_loadingComments) return;
    setState(() => _loadingComments = true);
    try {
      final comments = await widget.onLoadComments();
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

      final newComment = await widget.onAddComment(
        content,
        parentId: parentId,
        replyId: replyId,
      );

      if (newComment != null && mounted) {
        _input.clear();
        setState(() {
          _replyingTo = null;
          // If we have user info from the controller (via parent), we could inject it here.
          // For now, if the API doesn't return user info, we might need to rely on what we have.
          // Or assume the API returns the full comment object including user details.

          // Check if we need to inject current user info if it's missing from response
          // This depends on what the API returns in newComment
          _comments.add(newComment);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submittingComment = false);
      }
    }
  }

  Future<void> _likeComment(int commentId) async {
    final updatedComment = await widget.onLikeComment(commentId);
    if (updatedComment != null && mounted) {
      setState(() {
        final index = _comments.indexWhere((c) => c.comsId == commentId);
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            likes: updatedComment.likes,
          );
        }
      });
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
      final success = await widget.onDeleteComment(commentId);
      if (success && mounted) {
        setState(() {
          _comments.removeWhere((c) => c.comsId == commentId);
        });
      }
    }
  }

  Widget _buildCommentItem(CommentModel comment) {
    return GestureDetector(
      onLongPress: () => _deleteComment(comment.comsId),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  comment.userMedia.isNotEmpty
                      ? NetworkImage(comment.userMedia)
                      : null,
              child:
                  comment.userMedia.isEmpty
                      ? Text(
                        comment.initials,
                        style: const TextStyle(fontSize: 10),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
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
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        comment.timeAgo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (widget.currentUserId != null &&
                          widget.currentUserId == comment.publishId)
                        GestureDetector(
                          onTap: () => _deleteComment(comment.comsId),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(comment.content, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () => _likeComment(comment.comsId),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
                if (comment.likes > 0)
                  Text(
                    '${comment.likes}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _startReply(comment),
                  child: const Icon(Icons.reply, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentList() {
    if (_loadingComments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No comments yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    // Identify roots and group children
    final roots =
        _comments.where((c) => c.parentId == null || c.parentId == 0).toList();

    // Handle orphans: comments that have a parentId but the parent is not in the list
    // This ensures we don't lose comments if the parent is missing
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
          padding: EdgeInsets.only(left: depth * 24.0),
          child: _buildCommentItem(comment),
        ),
        if (children.isNotEmpty)
          ...children.map(
            (child) => _buildCommentNode(child, byParent, depth: depth + 1),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  post.userMedia.isNotEmpty
                      ? NetworkImage(post.userMedia)
                      : null,
              child: post.userMedia.isEmpty ? Text(post.initials) : null,
            ),
            title: Text(
              post.userName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(post.timeAgo),
            trailing: const Icon(Icons.more_vert),
          ),
          if (post.postCaption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(post.postCaption),
            ),
          const SizedBox(height: 8),
          if (post.postMedia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  0,
                ), // Full width usually looks better or slightly rounded
                child: Image.network(
                  post.postMedia,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  errorBuilder:
                      (ctx, err, stack) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onLike,
                  icon: const Icon(Icons.favorite_border),
                ),
                Text('${post.postLikes}'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _toggleComments,
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('${post.commentsCount}'),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            crossFadeState:
                _showComments
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentList(),

                  const Divider(),
                  if (_replyingTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingTo!.userName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
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
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitComment,
                        icon:
                            _submittingComment
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
