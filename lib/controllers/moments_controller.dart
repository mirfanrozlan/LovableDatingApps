import 'dart:io';
import 'package:flutter/material.dart';
import '../models/moment_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/moments_service.dart';

enum MomentsType { all, friends, me }

class MomentsController extends ChangeNotifier {
  final MomentsType type;
  final _service = MomentsService();
  List<MomentModel> _moments = [];
  UserModel? _userProfile;
  bool _loading = false;
  String? _error;
  int? _currentUserId;

  MomentsController({this.type = MomentsType.all});

  List<MomentModel> get moments => _moments;
  UserModel? get userProfile => _userProfile;
  bool get loading => _loading;
  String? get error => _error;
  int? get currentUserId => _currentUserId;

  Future<void> loadMoments() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUserId = await _service.getCurrentUserId();
      if (type == MomentsType.all) {
        _moments = await _service.getMoments();
      } else if (type == MomentsType.friends) {
        _moments = await _service.getFriendMoments();
      } else if (type == MomentsType.me) {
        if (_currentUserId != null) {
          // Load profile and moments in parallel
          final results = await Future.wait([
            _service.getUserDetails(_currentUserId!),
            _service.getMyMoments(),
          ]);
          _userProfile = results[0] as UserModel;
          final rawMoments = results[1] as List<MomentModel>;

          // Inject user info into moments since /api/getUserPost doesn't return it
          _moments =
              rawMoments
                  .map(
                    (m) => m.copyWith(
                      userName: _userProfile!.name,
                      userMedia: _userProfile!.media,
                    ),
                  )
                  .toList();
        } else {
          _moments = await _service.getMyMoments(); // This will throw if no ID
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _moments = [];
    await loadMoments();
  }

  Future<void> likePost(int postId) async {
    try {
      final updatedPost = await _service.likePost(postId);
      final index = _moments.indexWhere((m) => m.postId == postId);
      if (index != -1) {
        _moments[index] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<List<CommentModel>> loadComments(int postId) async {
    try {
      return await _service.getComments(postId);
    } catch (e) {
      print('Error loading comments: $e');
      return [];
    }
  }

  Future<CommentModel?> addComment(
    int postId,
    String content, {
    int? parentId,
    int? replyId,
  }) async {
    try {
      final comment = await _service.addComment(
        postId,
        content,
        parentId: parentId,
        replyId: replyId,
      );
      if (comment != null) {
        if (_currentUserId == null) {
          _currentUserId = comment.publishId;
        }

        // Update comment count locally
        final index = _moments.indexWhere((m) => m.postId == postId);
        if (index != -1) {
          final current = _moments[index];
          _moments[index] = current.copyWith(
            commentsCount: current.commentsCount + 1,
          );
          notifyListeners();
        }
      }
      return comment;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Future<CommentModel?> likeComment(int commentId) async {
    try {
      return await _service.likeComment(commentId);
    } catch (e) {
      print('Error liking comment: $e');
      return null;
    }
  }

  Future<bool> deleteComment(int commentId, int postId) async {
    try {
      final success = await _service.deleteComment(commentId);
      if (success) {
        // Update comment count locally
        final index = _moments.indexWhere((m) => m.postId == postId);
        if (index != -1) {
          final current = _moments[index];
          if (current.commentsCount > 0) {
            _moments[index] = current.copyWith(
              commentsCount: current.commentsCount - 1,
            );
            notifyListeners();
          }
        }
      }
      return success;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  Future<bool> createPost(String content, File? image) async {
    try {
      return await _service.createPost(content, image);
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }
}
