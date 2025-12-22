import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/privacy_model.dart';

class PrivacyService {
  final _storage = const FlutterSecureStorage();
  final String _authority = 'demo.mazri-minecraft.xyz';

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<String?> _getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<PrivacyModel?> getPrivacy() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/getPrivacy');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PrivacyModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching privacy settings: $e');
      return null;
    }
  }

  Future<PrivacyModel?> setPrivacy(PrivacyModel privacy) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.https(_authority, '/api/setPrivacy');

      final Map<String, dynamic> body = {
        'privacy_id': privacy.privacyId.toString(),
        'user_id': privacy.userId.toString(),
        'show_profile': privacy.showProfile ? '1' : '0',
        'show_incognito': privacy.showIncognito ? '1' : '0',
        'show_age': privacy.showAge ? '1' : '0',
        'show_distance': privacy.showDistance ? '1' : '0',
        'show_precise': privacy.showPrecise ? '1' : '0',
        'show_status': privacy.showStatus ? '1' : '0',
        'show_previous': privacy.showPrevious ? '1' : '0',
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PrivacyModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error setting privacy settings: $e');
      return null;
    }
  }
}
