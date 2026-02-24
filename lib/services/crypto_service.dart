import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  final _storage = const FlutterSecureStorage();
  static const String _masterKeyName = 'e2ee_master_key';

  /// Gets or creates a master key for this device.
  /// NOTE: In a real E2EE app, this would be derived from a user secret
  /// or exchanged via ECDH. For this demo, we use a consistent seed
  /// to allow multiple devices/users to simulate the E2EE flow.
  Future<String> _getOrCreateMasterKey() async {
    String? masterKey = await _storage.read(key: _masterKeyName);
    if (masterKey == null) {
      // For demonstration purposes, we use a fixed seed to ensure 
      // both parties can derive the same key. In production, 
      // this would be a truly random key exchanged securely.
      final seed = "lovable-dating-app-e2ee-secret-seed";
      final key = encrypt.Key.fromUtf8(seed.padRight(32, '0').substring(0, 32));
      masterKey = key.base64;
      await _storage.write(key: _masterKeyName, value: masterKey);
    }
    return masterKey;
  }

  /// Derives a chat-specific key from the master key and a pair of user IDs.
  /// This ensures both users in a 1-on-1 chat derive the same key if they share the master secret.
  /// Note: In real E2EE, you'd use ECDH to derive a shared secret.
  Future<encrypt.Key> _deriveChatKey(String otherUserId) async {
    final masterKey = await _getOrCreateMasterKey();
    
    // To make it consistent for both sides, we need the current user ID
    final myId = await _storage.read(key: 'user_id') ?? '0';
    
    // Sort IDs to get a consistent pair identifier
    final ids = [myId, otherUserId]..sort();
    final pairId = ids.join('_');
    
    // Simple key derivation: HMAC-SHA256(masterKey, pairId)
    final hmac = Hmac(sha256, base64Decode(masterKey));
    final digest = hmac.convert(utf8.encode(pairId));
    
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts a plaintext message for a specific chat.
  /// Returns a JSON string containing the IV and the encrypted message.
  Future<String> encryptMessage(String chatId, String plaintext) async {
    final key = await _deriveChatKey(chatId);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // We return a combined format that the relay (server) sees as just a string
    return jsonEncode({
      'iv': iv.base64,
      'content': encrypted.base64,
      'v': '1', // Versioning for future changes
    });
  }

  /// Decrypts an encrypted message from a specific chat.
  Future<String> decryptMessage(String chatId, String encryptedJson) async {
    try {
      final data = jsonDecode(encryptedJson);
      if (data is! Map || !data.containsKey('content') || !data.containsKey('iv')) {
        // Not an encrypted message or wrong format, return as is (fallback)
        return encryptedJson;
      }

      final key = await _deriveChatKey(chatId);
      final iv = encrypt.IV.fromBase64(data['iv']);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      return encrypter.decrypt64(data['content'], iv: iv);
    } catch (e) {
      print('Decryption error: $e');
      return '[Decryption Error]';
    }
  }
}
