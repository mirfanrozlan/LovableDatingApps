import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/messages/chat_invite_model.dart';
import '../models/user_model.dart';
import 'package:centrifuge/centrifuge.dart';

class MessagesService {
  static const String _authority = 'demo.mazri-minecraft.xyz';
  final _storage = const FlutterSecureStorage();
  late Client centrifuge;
  final _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _incomingController.stream;

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
        print('MessagesService.getInvites: ${response.body}');
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

  Future<bool> notifyIncomingCall({
    required String uuid,
    required String callerName,
    required String callerHandle,
    String? callerAvatar,
    required int callType,
    required int calleeUserId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final uri = Uri.https(_authority, '/api/notify/incoming-call');
      final payload = {
        'room_id': uuid, // Use room_id instead of uuid
        'caller_id': int.tryParse(callerHandle) ?? 0, // Use caller_id
        'caller_name': callerName, // Use caller_name
        'caller_avatar': callerAvatar ?? '', // Use caller_avatar
        'call_type': callType == 1 ? 'video' : 'audio', // Use call_type
        'callee_id': calleeUserId,
        // Keep old format for backward compatibility
        'uuid': uuid,
        'callerName': callerName,
        'callerHandle': callerHandle,
        'callerAvatar': callerAvatar ?? '',
        'callType': callType.toString(),
      };
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error notify incoming call: $e');
      return false;
    }
  }

  Future<bool> notifyIncomingCaller({
    required String uuid,
    required String callerName,
    required String callerHandle,
    String? callerAvatar,
    required int callType,
    required int calleeUserId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final uri = Uri.https(_authority, '/api/notify/incoming-caller');
      final payload = {
        'room_id': uuid, // Use room_id instead of uuid
        'caller_id': int.tryParse(callerHandle) ?? 0, // Use caller_id
        'caller_name': callerName, // Use caller_name
        'caller_avatar': callerAvatar ?? '', // Use caller_avatar
        'call_type': callType == 1 ? 'video' : 'audio', // Use call_type
        'callee_id': calleeUserId,
        // Keep old format for backward compatibility
        'uuid': uuid,
        'callerName': callerName,
        'callerHandle': callerHandle,
        'callerAvatar': callerAvatar ?? '',
        'callType': callType.toString(),
      };
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error notify incoming caller: $e');
      return false;
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final connToken = (data['token'] ?? '') as String;

        centrifuge = createClient(
          "wss://centri.mazri-minecraft.xyz/connection/websocket",
          ClientConfig(token: connToken, getToken: (event) async => connToken),
        );
        await centrifuge.connect();
        return data;
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final channel = (data['channel'] ?? '') as String;
        final subToken = (data['token'] ?? '') as String;
        final sub = centrifuge.newSubscription(
          channel,
          SubscriptionConfig(token: subToken),
        );
        sub.publication.listen((event) {
          print(event);
          try {
            final raw = utf8.decode(event.data);
            final payload = jsonDecode(raw) as Map<String, dynamic>;
            final msg = payload['message'];
            if (msg is String) {
              final trimmed = msg.trim();
              final emojiOnly = _isEmojiOnly(trimmed);
              payload['render_large_emoji'] = emojiOnly;
            }
            _incomingController.add(payload);
          } catch (e) {
            print('Error on listening data : ' + e.toString());
          }
        });
        await sub.subscribe();
        await _fetchHistory(channel, limit: 100);
        return data;
      }
      return null;
    } catch (e) {
      print('Error subscribing to chat $userId: $e');
      return null;
    }
  }

  Future<void> _fetchHistory(String channel, {int limit = 100}) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final uri = Uri.https(_authority, '/api/chat/history', {
        'channel': channel,
        'limit': limit.toString(),
      });
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['messages'] ?? []) as List<dynamic>;
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            _incomingController.add(item);
          }
        }
      }
    } catch (e) {
      print('Error fetching history for $channel: $e');
    }
  }

  Future<Map<String, dynamic>?> setTyping(int receiverId, bool typing) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/chat/typing');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'receiver_id': receiverId, 'typing': typing}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error setting typing to $typing for $receiverId: $e');
      return null;
    }
  }

  bool _isEmojiOnly(String input) {
    if (input.isEmpty) return false;
    final pattern = RegExp(
      r'^[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{1F1E6}-\u{1F1FF}\u200D\uFE0F]+$',
      unicode: true,
    );
    return pattern.hasMatch(input);
  }
}
