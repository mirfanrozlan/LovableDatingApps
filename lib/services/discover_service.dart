import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discover_profile_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverService {
  Future<List<DiscoverProfileModel>> getRandomPeople({int page = 1}) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      var response = await http.get(
        Uri.https(
          'demo.mazri-minecraft.xyz', 
          '/api/getRandomPeople',
          {'page': page.toString()}
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> users = data['data'];
        return users.map((e) => DiscoverProfileModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Discover error: $e');
      return [];
    }
  }
}
