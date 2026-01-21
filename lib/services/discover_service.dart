import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discover_profile_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiscoverService {
  static const String _baseUrl = 'demo.mazri-minecraft.xyz';

  /// Sends an invite to the target user when current user swipes right (likes).
  /// Returns a Map with 'success' bool and optionally 'inviteId' if there's a pending invite from the other user.
  Future<Map<String, dynamic>> sendInvite(int targetUserId) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      final response = await http.post(
        Uri.https(_baseUrl, '/api/sendInvite/$targetUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('DiscoverService.sendInvite: status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Invite sent successfully',
          'inviteId': data['invite_id'],
          'isMatch': data['is_match'] ?? false,
        };
      }
      return {'success': false, 'message': 'Failed to send invite'};
    } catch (e) {
      print('DiscoverService.sendInvite error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Responds to an invite (accept/reject).
  /// Used when user B swipes right on user A who already sent an invite.
  Future<Map<String, dynamic>> respondInvite(int inviteId, String response) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      final httpResponse = await http.post(
        Uri.https(_baseUrl, '/api/respondInvite/$inviteId/$response'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('DiscoverService.respondInvite: status=${httpResponse.statusCode} body=${httpResponse.body}');
      if (httpResponse.statusCode == 200) {
        final data = jsonDecode(httpResponse.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Invite responded successfully',
        };
      }
      return {'success': false, 'message': 'Failed to respond to invite'};
    } catch (e) {
      print('DiscoverService.respondInvite error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Checks if there's a pending invite from a specific user.
  /// Returns the invite_id if found, null otherwise.
  Future<int?> checkPendingInvite(int fromUserId) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      final response = await http.get(
        Uri.https(_baseUrl, '/api/checkInvite/$fromUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('DiscoverService.checkPendingInvite: status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['has_invite'] == true) {
          return data['invite_id'];
        }
      }
      return null;
    } catch (e) {
      print('DiscoverService.checkPendingInvite error: $e');
      return null;
    }
  }

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
