import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discover_profile_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverService {
  Future<List<DiscoverProfileModel>> getRandomPeople({
    int page = 1,
    int limit = 5,
    int? distance,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (distance != null) queryParams['distance'] = distance.toString();
      if (gender != null) queryParams['gender'] = gender;
      if (minAge != null) queryParams['minAge'] = minAge.toString();
      if (maxAge != null) queryParams['maxAge'] = maxAge.toString();

      var response = await http.get(
        Uri.https(
          'demo.mazri-minecraft.xyz',
          '/api/getRandomPeople',
          queryParams,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> users = data['data'];
        final mapped =
            users.map((e) => DiscoverProfileModel.fromJson(e)).toList();
        return mapped;
      }
      return [];
    } catch (e) {
      print('Discover error: $e');
      return [];
    }
  }
}
