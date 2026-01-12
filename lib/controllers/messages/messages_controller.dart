import 'dart:convert';
import 'dart:async';
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

  final List<MessageModel> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  String? _activeChatId;
  bool _isTyping = false;
  final Set<String> _knownMessageIds = {};

  MessagesController() {
    // Optionally load on init if singleton, but usually called from view
  }

  @override
  void dispose() {
    _msgSub?.cancel();
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
    return _messages.where((m) => m.chatId == chatId).toList();
  }

  bool get isTyping => _isTyping;

  Future<void> sendMessage(String chatId, String text) async {
    final userId = int.tryParse(chatId);
    if (userId == null) return;

    // Optimistic update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final largeEmoji = _isEmojiOnly(text.trim());
    final msg = MessageModel(
      id: tempId,
      chatId: chatId,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      largeEmoji: largeEmoji,
    );

    _messages.add(msg);
    notifyListeners();

    try {
      final result = await _service.sendMessage(userId, text);
      if (result == null) {
        // Failed: Remove message or mark as error
        _removeMessageById(tempId);
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
      _removeMessageById(tempId);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> startIncomingCall({
    required int calleeUserId,
    required String uuid,
    required String callerName,
    required String callerHandle,
    String? callerAvatar,
    required int callType,
  }) async {
    try {
      final ok = await _service.notifyIncomingCall(
        uuid: uuid,
        callerName: callerName,
        callerHandle: callerHandle,
        callerAvatar: callerAvatar,
        callType: callType,
        calleeUserId: calleeUserId,
      );
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> setTyping(String chatId, bool typing) async {
    final userId = int.tryParse(chatId);
    if (userId == null) return;
    try {
      await _service.setTyping(userId, typing);
    } catch (_) {}
  }

  void _removeMessageById(String msgId) {
    _messages.removeWhere((m) => m.id == msgId);
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

    _messages.add(msg);
    notifyListeners();
  }

  // Real-time connection stub - Pusher removed as requested
  Future<void> connectToChat(String chatId) async {
    final userId = int.tryParse(chatId);
    if (userId == null) return;

    try {
      _activeChatId = chatId;
      _messages.clear();

      _msgSub?.cancel();
      _msgSub = _service.messages.listen((data) {
        try {
          if (data['type'] == 'delete' && data['id'] != null) {
            _removeMessageById(data['id'].toString());
            notifyListeners();
            return;
          }
          if (data['type'] == 'typing') {
            final senderId = data['sender_id'];
            final typing = data['typing'] == true;
            if (_activeChatId != null && senderId != null) {
              _isTyping = typing && senderId.toString() == _activeChatId;
              notifyListeners();
            }
            return;
          }

          final senderId = data['sender_id'];
          final text = data['message'];
          final ts = data['ts'];
          if (senderId == null || text == null || ts == null) return;
          final idStr = data['id']?.toString();
          if (idStr != null && _knownMessageIds.contains(idStr)) return;

          final isMe =
              int.tryParse(chatId) != null && senderId != int.parse(chatId);
          final when = _parseTs(ts);
          final largeEmoji = _isEmojiOnly(text.toString().trim());
          if (isMe) {
            final idx = _messages.lastIndexWhere(
              (m) => m.chatId == chatId && m.isMe && m.text == text.toString(),
            );
            if (idx != -1) {
              _messages[idx] = MessageModel(
                id: idStr ?? when.millisecondsSinceEpoch.toString(),
                chatId: chatId,
                text: text.toString(),
                timestamp: when,
                isMe: true,
                largeEmoji: largeEmoji,
              );
            } else {
              final msg = MessageModel(
                id: idStr ?? when.millisecondsSinceEpoch.toString(),
                chatId: chatId,
                text: text.toString(),
                timestamp: when,
                isMe: true,
                largeEmoji: largeEmoji,
              );
              _messages.add(msg);
            }
          } else {
            final msg = MessageModel(
              id: idStr ?? when.millisecondsSinceEpoch.toString(),
              chatId: chatId,
              text: text.toString(),
              timestamp: when,
              isMe: false,
              largeEmoji: largeEmoji,
            );
            _messages.add(msg);
          }
          if (idStr != null) _knownMessageIds.add(idStr);
          notifyListeners();
        } catch (_) {}
      });

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

      print('Chat subscription active for $chatId');
    } catch (e) {
      print('Error connecting to chat: $e');
    }
  }

  DateTime _parseTs(dynamic ts) {
    if (ts is int) {
      return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    }
    if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
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
