import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/moment_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class MomentsService {
  static const String _authority = 'demo.mazri-minecraft.xyz';
  static const String _path = '/api/getRandomPost';
  final _storage = const FlutterSecureStorage();

  Future<bool> createPost(String content, File? imageFile) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {'Accept': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/createPost');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.fields['post_caption'] = content;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'post_media', // API expects 'post_media'
            imageFile.path,
          ),
        );
      } else {
        request.fields['post_media'] =
            ' '; // Send a space to bypass "cannot be null"
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
          'Failed to create post: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  Future<List<MomentModel>> getMoments() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, _path);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> data;

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is List) {
          data = decoded['data'];
        } else {
          // If the structure is unexpected, return an empty list or throw
          print('Unexpected API response structure: $decoded');
          return [];
        }

        return data.map((json) => MomentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load moments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching moments: $e');
    }
  }

  Future<List<MomentModel>> getFriendMoments() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/getFriendPost');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> data;

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is List) {
          data = decoded['data'];
        } else {
          return [];
        }

        return data.map((json) => MomentModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load friend moments: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching friend moments: $e');
    }
  }

  Future<List<MomentModel>> getMyMoments() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await getCurrentUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      return await getUserMoments(userId);
    } catch (e) {
      throw Exception('Error fetching my moments: $e');
    }
  }

  Future<List<MomentModel>> getUserMoments(int userId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/getUserPost/$userId');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> data;

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is List) {
          data = decoded['data'];
        } else {
          return [];
        }

        return data.map((json) => MomentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user moments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user moments: $e');
    }
  }

  Future<UserModel> getUserDetails(int userId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/getUser/$userId');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        return UserModel.fromJson(decoded);
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  Future<MomentModel> likePost(int postId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/likePost/$postId');
      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        return MomentModel.fromJson(decoded);
      } else {
        throw Exception('Failed to like post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking post: $e');
    }
  }

  Future<List<CommentModel>> getComments(int postId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/getComment/$postId');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> data;

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is List) {
          data = decoded['data'];
        } else {
          return [];
        }

        return data.map((json) => CommentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  Future<CommentModel?> addComment(
    int postId,
    String content, {
    int? parentId,
    int? replyId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/setComment');
      final body = {'post_id': postId, 'coms_content': content};
      if (parentId != null) body['parent_id'] = parentId;
      if (replyId != null) body['reply_id'] = replyId;

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        // Opportunistically cache user ID from the response
        if (decoded['publish_id'] != null) {
          await _storage.write(
            key: 'user_id',
            value: decoded['publish_id'].toString(),
          );
        }

        return CommentModel.fromJson(decoded);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  Future<CommentModel> likeComment(int commentId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/likeComment/$commentId');
      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        // Note: The response might not have user details, so we trust the caller to merge/handle it.
        return CommentModel.fromJson(decoded);
      } else {
        throw Exception('Failed to like comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking comment: $e');
    }
  }

  Future<bool> deleteComment(int replyId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.https(_authority, '/api/deleteComment/$replyId');
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['deleted'] == true;
      } else {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.https(_authority, '/api/deletePost/$postId');
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty) return true;
        try {
          final decoded = json.decode(body);
          if (decoded is Map<String, dynamic>) {
            if (decoded.containsKey('deleted')) {
              final v = decoded['deleted'];
              if (v is bool) return v;
              if (v is num) return v != 0;
              if (v is String) return v.toLowerCase() == 'true' || v == '1';
            }
            if (decoded.containsKey('success')) {
              final v = decoded['success'];
              if (v is bool) return v;
              if (v is num) return v != 0;
              if (v is String) return v.toLowerCase() == 'true' || v == '1';
            }
            if (decoded.containsKey('status')) {
              final s = decoded['status'].toString().toLowerCase();
              if (s == 'ok' || s == 'success') return true;
            }
          }
          return true;
        } catch (_) {
          return true;
        }
      }
      throw Exception('Failed to delete post: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      // First try to get from explicit storage
      final idStr = await _storage.read(key: 'user_id');
      if (idStr != null) {
        return int.tryParse(idStr);
      }

      // If not found, try to decode from token
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        final userId = _getUserIdFromToken(token);
        if (userId != null) {
          // Store it for future use
          await _storage.write(key: 'user_id', value: userId.toString());
          return userId;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  int? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var payload = parts[1];
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          return null;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> json = jsonDecode(decoded);

      // Try common JWT fields for user ID
      if (json.containsKey('user_id'))
        return int.tryParse(json['user_id'].toString());
      if (json.containsKey('sub')) return int.tryParse(json['sub'].toString());
      if (json.containsKey('id')) return int.tryParse(json['id'].toString());
      if (json.containsKey('uid')) return int.tryParse(json['uid'].toString());

      // If still not found, check if it's inside a 'data' or 'user' object
      if (json.containsKey('data') && json['data'] is Map) {
        final data = json['data'];
        if (data.containsKey('user_id'))
          return int.tryParse(data['user_id'].toString());
        if (data.containsKey('id')) return int.tryParse(data['id'].toString());
      }
      if (json.containsKey('user') && json['user'] is Map) {
        final user = json['user'];
        if (user.containsKey('user_id'))
          return int.tryParse(user['user_id'].toString());
        if (user.containsKey('id')) return int.tryParse(user['id'].toString());
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
