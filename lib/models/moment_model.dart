class MomentModel {
  final int postId;
  final int userId;
  final String postMedia;
  final String postCaption;
  final int postLikes;
  final String postCreatedAt;
  final String postUpdatedAt;
  final String userName;
  final String userMedia;
  final int commentsCount;

  MomentModel({
    required this.postId,
    required this.userId,
    required this.postMedia,
    required this.postCaption,
    required this.postLikes,
    required this.postCreatedAt,
    required this.postUpdatedAt,
    required this.userName,
    required this.userMedia,
    required this.commentsCount,
  });

  factory MomentModel.fromJson(Map<String, dynamic> json) {
    String resolveUrl(String? url) {
      if (url == null || url.trim().isEmpty) return '';
      final cleanUrl = url.trim().replaceAll('`', '').replaceAll('\\', '/');
      if (cleanUrl.startsWith('http')) return cleanUrl;
      if (cleanUrl.startsWith('/'))
        return 'https://demo.mazri-minecraft.xyz$cleanUrl';
      return 'https://demo.mazri-minecraft.xyz/$cleanUrl';
    }

    return MomentModel(
      postId: json['post_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      postMedia: resolveUrl(json['post_media']),
      postCaption: json['post_caption'] ?? '',
      postLikes: json['post_likes'] ?? 0,
      postCreatedAt: json['post_createdAt'] ?? '',
      postUpdatedAt: json['post_updatedAt'] ?? '',
      userName: json['user_name'] ?? 'Unknown',
      userMedia: resolveUrl(json['user_media']),
      commentsCount: json['comments_count'] ?? 0,
    );
  }

  // Helpers for UI
  String get timeAgo {
    if (postCreatedAt.isEmpty) return '';
    try {
      final normalized = postCreatedAt.contains(' ')
          ? postCreatedAt.replaceFirst(' ', 'T')
          : postCreatedAt;
      final dt = DateTime.parse(normalized);
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

  MomentModel copyWith({
    int? postId,
    int? userId,
    String? postMedia,
    String? postCaption,
    int? postLikes,
    String? postCreatedAt,
    String? postUpdatedAt,
    String? userName,
    String? userMedia,
    int? commentsCount,
  }) {
    return MomentModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      postMedia: postMedia ?? this.postMedia,
      postCaption: postCaption ?? this.postCaption,
      postLikes: postLikes ?? this.postLikes,
      postCreatedAt: postCreatedAt ?? this.postCreatedAt,
      postUpdatedAt: postUpdatedAt ?? this.postUpdatedAt,
      userName: userName ?? this.userName,
      userMedia: userMedia ?? this.userMedia,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
