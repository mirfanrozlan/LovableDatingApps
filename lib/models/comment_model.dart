class CommentModel {
  final int comsId;
  final int postId;
  final int publishId;
  final int? parentId;
  final int? replyId;
  final String content;
  final int likes;
  final String createdAt;
  final String userName;
  final String userMedia;
  final bool likedByMe;

  CommentModel({
    required this.comsId,
    required this.postId,
    required this.publishId,
    this.parentId,
    this.replyId,
    required this.content,
    required this.likes,
    required this.createdAt,
    required this.userName,
    required this.userMedia,
    this.likedByMe = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String resolveUrl(String? url) {
      if (url == null || url.trim().isEmpty) return '';
      final cleanUrl = url.trim().replaceAll('`', '');
      if (cleanUrl.startsWith('http')) return cleanUrl;
      if (cleanUrl.startsWith('/'))
        return 'https://demo.mazri-minecraft.xyz$cleanUrl';
      return 'https://demo.mazri-minecraft.xyz/$cleanUrl';
    }

    return CommentModel(
      comsId: json['coms_id'] ?? 0,
      postId: json['post_id'] ?? 0,
      publishId: json['publish_id'] ?? 0,
      parentId: json['parent_id'],
      replyId: json['reply_id'],
      content: json['coms_content'] ?? '',
      likes: json['coms_likes'] ?? 0,
      createdAt: json['coms_createdAt'] ?? '',
      userName: json['user_name'] ?? 'Unknown',
      userMedia: resolveUrl(json['user_media']),
      likedByMe: (json['liked_by_me'] ?? false) == true,
    );
  }

  String get timeAgo {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  String get initials {
    if (userName.isEmpty) return '';
    final parts = userName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  CommentModel copyWith({
    int? comsId,
    int? postId,
    int? publishId,
    int? parentId,
    int? replyId,
    String? content,
    int? likes,
    String? createdAt,
    String? userName,
    String? userMedia,
    bool? likedByMe,
  }) {
    return CommentModel(
      comsId: comsId ?? this.comsId,
      postId: postId ?? this.postId,
      publishId: publishId ?? this.publishId,
      parentId: parentId ?? this.parentId,
      replyId: replyId ?? this.replyId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userMedia: userMedia ?? this.userMedia,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}
