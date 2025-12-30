import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../models/messages/message_model.dart';
import '../../services/messages_service.dart';

class MessagesController extends ChangeNotifier {
  final MessagesService _service = MessagesService();

  List<ChatSummaryModel> _chats = [];
  bool _isLoading = false;
  String? _error;

  List<ChatSummaryModel> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cache for conversations (temporary until real-time is fully hooked up)
  final Map<String, List<MessageModel>> _conversations = {};

  MessagesController() {
    // Optionally load on init if singleton, but usually called from view
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final invites = await _service.getInvites();
      _chats =
          invites.map((invite) {
            // Map invite to ChatSummaryModel
            // Since we don't have message history yet, we show placeholder
            return ChatSummaryModel(
              id: invite.user.id.toString(),
              name: invite.user.name,
              initials:
                  invite.user.name.isNotEmpty
                      ? invite.user.name.substring(0, 1).toUpperCase()
                      : '?',
              avatarUrl: invite.user.media,
              lastMessage: 'Say hi!', // Placeholder
              time: '',
              unread: 0,
            );
          }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MessageModel> getConversation(String chatId) {
    return _conversations[chatId] ?? [];
  }

  Future<void> sendMessage(String chatId, String text) async {
    final userId = int.tryParse(chatId);
    if (userId == null) return;

    // Optimistic update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final msg = MessageModel(
      id: tempId,
      chatId: chatId,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    _addMessageToCache(chatId, msg);
    notifyListeners();

    try {
      final result = await _service.sendMessage(userId, text);
      if (result == null) {
        // Failed: Remove message or mark as error
        _removeMessageFromCache(chatId, tempId);
        _error = "Failed to send message";
        notifyListeners();
      } else {
        // Success: Update message with server data if needed
        if (result.containsKey('data')) {
          final data = result['data'];
          if (data != null && data is Map<String, dynamic>) {
            // Update the optimistic message with real timestamp/ID if available
            // For now, we just keep the optimistic one as it's already displayed.
            // If we wanted to be precise:
            // _removeMessageFromCache(chatId, tempId);
            // final newMsg = MessageModel(
            //   id: data['ts'].toString(),
            //   chatId: chatId,
            //   text: data['message'],
            //   timestamp: DateTime.fromMillisecondsSinceEpoch(data['ts'] * 1000),
            //   isMe: true,
            // );
            // _addMessageToCache(chatId, newMsg);
            // notifyListeners();
          }
        }
      }
    } catch (e) {
      _removeMessageFromCache(chatId, tempId);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setTyping(String chatId, bool typing) async {
    final userId = int.tryParse(chatId);
    if (userId == null) return;
    try {
      await _service.setTyping(userId, typing);
    } catch (_) {}
  }

  void _addMessageToCache(String chatId, MessageModel msg) {
    if (_conversations.containsKey(chatId)) {
      _conversations[chatId]!.add(msg);
    } else {
      _conversations[chatId] = [msg];
    }
  }

  void _removeMessageFromCache(String chatId, String msgId) {
    if (_conversations.containsKey(chatId)) {
      _conversations[chatId]!.removeWhere((m) => m.id == msgId);
    }
  }

  // Called when receiving a message via WebSocket (or other means)
  void handleIncomingMessage(Map<String, dynamic> data) {
    // data structure based on API log:
    // { "sender_id": 21, "receiver_id": 43, "message": "hi", "ts": 1766249180 }

    final senderId = data['sender_id'].toString();
    final message = data['message'] as String;
    final ts = data['ts'] as int;

    final msg = MessageModel(
      id: ts.toString(), // use timestamp as ID for now
      chatId: senderId,
      text: message,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      isMe: false,
    );

    _addMessageToCache(senderId, msg);
    notifyListeners();
  }

  // Real-time connection stub - Pusher removed as requested
  Future<void> connectToChat(String chatId) async {
    final userId = int.tryParse(chatId);
    if (userId == null) return;

    try {
      // Call connectChat first to establish connection
      final connectData = await _service.connectChat();
      if (connectData == null) {
        print('Failed to connect to chat system');
      }


      final subData = await _service.subscribeChat(userId);
      if (subData == null) {
        print('Failed to get subscription data');
        return;
      }

      print('Chat subscription active for $chatId (HTTP only)');
    } catch (e) {
      print('Error connecting to chat: $e');
    }
  }
}
