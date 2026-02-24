import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/messages/message_model.dart';

class LocalStorageService {
  static const String _encryptionKeyName = 'hive_encryption_key';
  final _storage = const FlutterSecureStorage();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _isInitialized = true;
  }

  /// Gets or creates a 256-bit encryption key for Hive
  Future<Uint8List> _getEncryptionKey() async {
    String? key = await _storage.read(key: _encryptionKeyName);
    if (key == null) {
      final secureKey = Hive.generateSecureKey();
      await _storage.write(key: _encryptionKeyName, value: base64UrlEncode(secureKey));
      return Uint8List.fromList(secureKey);
    }
    return base64Url.decode(key);
  }

  Future<Box> _getChatBox(String chatId) async {
    final encryptionKey = await _getEncryptionKey();
    return await Hive.openBox(
      'chat_$chatId',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  /// Saves a message to local encrypted storage
  Future<void> saveMessage(MessageModel message) async {
    final box = await _getChatBox(message.chatId);
    await box.put(message.id, {
      'id': message.id,
      'chatId': message.chatId,
      'text': message.text,
      'timestamp': message.timestamp.toIso8601String(),
      'isMe': message.isMe,
      'largeEmoji': message.largeEmoji,
    });
  }

  /// Loads all messages for a specific chat from local storage
  Future<List<MessageModel>> getMessages(String chatId) async {
    final box = await _getChatBox(chatId);
    final List<MessageModel> messages = [];
    
    for (var i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        messages.add(MessageModel(
          id: data['id'],
          chatId: data['chatId'],
          text: data['text'],
          timestamp: DateTime.parse(data['timestamp']),
          isMe: data['isMe'],
          largeEmoji: data['largeEmoji'] ?? false,
        ));
      }
    }
    
    // Sort by timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// Deletes a message from local storage
  Future<void> deleteMessage(String chatId, String messageId) async {
    final box = await _getChatBox(chatId);
    await box.delete(messageId);
  }
}
