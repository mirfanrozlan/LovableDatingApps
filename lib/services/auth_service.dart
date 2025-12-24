import 'package:mobile/models/auth/register_form_model.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class AuthService {
  Future<void> sendReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<bool> register(RegisterFormModel form) async {
    try {
      var response = await http.post(
        Uri.https('demo.mazri-minecraft.xyz', '/api/register'),
        body: {
          'users[user_name]': form.username,
          'users[user_gender]': form.gender,
          'users[user_age]': form.age.toString(),
          'users[user_desc]': form.bio,
          'users[user_education]': form.education,
          'users[user_subs]': 'no', // Default value
          'locations[user_address]': form.address,
          'locations[user_postcode]': form.postcode,
          'locations[user_state]': form.state,
          'locations[user_city]': form.city,
          'locations[user_country]': form.country,
          'credentials[user_email]': form.email,
          'credentials[user_phone]': form.phone,
          'credentials[user_password]': form.password,
          'credentials[cred_otp]': form.otp,
          'interest[user_interest]': form.interests,
          'preferences[pref_gender]': form.attractedGender,
          'preferences[pref_age_min]': form.minAge.toString(),
          'preferences[pref_age_max]': form.maxAge.toString(),
          'preferences[pref_location]': form.distanceKm.toString(),
        },
      );
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Automatically login or just return true to redirect
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<LoginStatus> login(String email, String password) async {
    try {
      var response = await http
          .post(
        Uri.https('demo.mazri-minecraft.xyz', '/api/login'),
        body: {'user_name': email, 'user_password': password},
      )
          .timeout(const Duration(seconds: 15));
      print(response.body);

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null) {
          final storage = const FlutterSecureStorage();
          await storage.write(key: 'auth_token', value: token);

          // Try to extract and store user ID
          final data = jsonDecode(response.body);
          String? userId;
          if (data['user_id'] != null) {
            userId = data['user_id'].toString();
          } else if (data['id'] != null) {
            userId = data['id'].toString();
          } else if (data['user'] != null) {
            if (data['user'] is Map) {
              final user = data['user'];
              if (user['user_id'] != null) {
                userId = user['user_id'].toString();
              } else if (user['id'] != null) {
                userId = user['id'].toString();
              }
            }
          } else if (data['data'] != null) {
            if (data['data'] is Map) {
              final d = data['data'];
              if (d['user_id'] != null) {
                userId = d['user_id'].toString();
              } else if (d['id'] != null) {
                userId = d['id'].toString();
              } else if (d['user'] != null && d['user'] is Map) {
                final user = d['user'];
                if (user['user_id'] != null) {
                  userId = user['user_id'].toString();
                } else if (user['id'] != null) {
                  userId = user['id'].toString();
                }
              }
            }
          }

          if (userId != null) {
            await storage.write(key: 'user_id', value: userId);
          }

          return LoginStatus.success;
        }
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return LoginStatus.invalid_credentials;
      }
      return LoginStatus.server_error;
    } on TimeoutException {
      return LoginStatus.network_error;
    } catch (e) {
      return LoginStatus.network_error;
    }
  }

  Future<void> logout() async {
    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/logout');
        await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_id');
    }
  }

  Future<bool> updateProfile({
    required int userId,
    required String username,
    required String gender,
    required int age,
    String bio = '',
    String education = '',
    String address = '',
    String postcode = '',
    String state = '',
    String city = '',
    String country = '',
    String interests = '',
    String email = '',
    String phone = '',
    String subscription = 'no',
  }) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/setProfile');
      final body = {
        'users[user_id]': userId.toString(),
        'users[user_name]': username,
        'users[user_gender]': gender,
        'users[user_age]': age.toString(),
        'users[user_desc]': bio,
        'users[user_education]': education,
        'users[user_subs]': subscription,
        'locations[user_address]': address,
        'locations[user_postcode]': postcode,
        'locations[user_state]': state,
        'locations[user_city]': city,
        'locations[user_country]': country,
        'interest[user_interest]': interests,
        'credentials[user_email]': email,
        'credentials[user_phone]': phone,
      };
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}

enum LoginStatus {
  success,
  invalid_credentials,
  network_error,
  server_error,
  unknown_error,
}
