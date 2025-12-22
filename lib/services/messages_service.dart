import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/messages/chat_invite_model.dart';
import '../models/user_model.dart';

class MessagesService {
  static const String _authority = 'demo.mazri-minecraft.xyz';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<List<ChatInviteModel>> getInvites() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final uri = Uri.https(_authority, '/api/getInvite');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatInviteModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching invites: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendMessage(
    int receiverId,
    String message,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/chat/send');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'receiver_id': receiverId, 'message': message}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  Future<UserModel?> getUser(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/getUser/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching user $userId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> connectChat() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/chat/connect');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error connecting to chat: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> subscribeChat(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/chat/subscribe/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error subscribing to chat $userId: $e');
      return null;
    }
  }
}
