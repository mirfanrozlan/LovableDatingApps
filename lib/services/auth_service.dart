import 'package:mobile/models/auth/register_form_model.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  Future<bool> sendResetOtp(String email) async {
    try {
      final response = await http.post(
        Uri.https('demo.mazri-minecraft.xyz', '/api/forgot/send-otp'),
        body: {'email': email},
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Send OTP error: $e');
      return false;
    }
  }

  Future<bool> verifyResetOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.https('demo.mazri-minecraft.xyz', '/api/forgot/verify-otp'),
        body: {'email': email, 'otp': otp},
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Verify OTP error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.https('demo.mazri-minecraft.xyz', '/api/forgot/reset'),
        body: {'email': email, 'otp': otp, 'new_password': newPassword},
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  Future<void> sendReset(String email) async {
    await sendResetOtp(email);
  }

  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.https(
        'demo.mazri-minecraft.xyz',
        '/api/fetchpref/$userId',
      );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get preferences error: $e');
      return null;
    }
  }

  Future<bool> register(RegisterFormModel form) async {
    try {
      // Calculate age from birthDate
      final now = DateTime.now();
      int age = now.year - form.birthDate.year;
      if (now.month < form.birthDate.month || 
          (now.month == form.birthDate.month && now.day < form.birthDate.day)) {
        age--;
      }
      
      var response = await http.post(
        Uri.https('demo.mazri-minecraft.xyz', '/api/register'),
        body: {
          'users[user_name]': form.username,
          'users[user_gender]': form.gender,
          'users[user_age]': age.toString(),
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

          // After successful login: request notification permission and register FCM token
          try {
            await _registerFcmToken();
          } catch (e) {
            // Do not fail login if FCM registration fails
            print('FCM token register error: $e');
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

  /// Request notification permission (if needed) and send the current
  /// Firebase Cloud Messaging token to the backend `/api/setToken` endpoint.
  ///
  /// This should be called after a successful login so the server can
  /// associate the device token with the authenticated user.
  Future<void> _registerFcmToken() async {
    try {
      // Request notification permission (Android 13+, iOS)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token is null or empty, skip setToken');
        return;
      }

      const storage = FlutterSecureStorage();
      final authToken = await storage.read(key: 'auth_token');
      if (authToken == null || authToken.isEmpty) {
        print('Auth token missing, cannot call /api/setToken');
        return;
      }

      final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/setToken');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: {'fcm_token': fcmToken},
      );

      print('setToken response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Error registering FCM token: $e');
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

  Future<Map<String, dynamic>?> _fetchPreferences(
    int userId,
    String? token,
  ) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final uri = Uri.https(
        'demo.mazri-minecraft.xyz',
        '/api/fetchpref/$userId',
      );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Fetch preferences error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchUserDetails(
    int userId,
    String? token,
  ) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/getUser/$userId');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Fetch user details error: $e');
      return null;
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
    String? prefGender,
    int? prefAgeMin,
    int? prefAgeMax,
    int? prefLocation,
  }) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Public helpers to fetch existing data
      Future<Map<String, dynamic>?> getPreferences(int userId) async {
        try {
          final h = <String, String>{'Accept': 'application/json'};
          if (token != null) h['Authorization'] = 'Bearer $token';
          final uri = Uri.https(
            'demo.mazri-minecraft.xyz',
            '/api/fetchpref/$userId',
          );
          final response = await http.get(uri, headers: h);
          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          }
          return null;
        } catch (_) {
          return null;
        }
      }

      Future<Map<String, dynamic>?> getUser(int userId) async {
        try {
          final h = <String, String>{'Accept': 'application/json'};
          if (token != null) h['Authorization'] = 'Bearer $token';
          final uri = Uri.https(
            'demo.mazri-minecraft.xyz',
            '/api/getUser/$userId',
          );
          final response = await http.get(uri, headers: h);
          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          }
          return null;
        } catch (_) {
          return null;
        }
      }

      // Fetch current data to preserve unedited fields
      final currentUser = await getUser(userId);
      final currentPrefs = await getPreferences(userId);

      final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/updateProfile');

      final body = {
        'users[user_name]':
            (username.trim().isEmpty
                ? (currentUser?['user_name'] ?? '')
                : username),
        'users[user_gender]':
            (gender.trim().isEmpty
                ? (currentUser?['user_gender'] ?? '')
                : gender),
        'users[user_age]':
            (age <= 0
                ? (currentUser?['user_age'] ?? 0).toString()
                : age.toString()),
        'users[user_desc]':
            (bio.trim().isEmpty ? (currentUser?['user_desc'] ?? '') : bio),
        'users[user_education]':
            (education.trim().isEmpty
                ? (currentUser?['user_education'] ?? '')
                : education),
        'users[user_subs]':
            (subscription.trim().isEmpty
                ? (currentUser?['user_subs'] ?? 'no')
                : subscription),
        'users[user_media]':
            currentUser?['user_media'] ?? 'Assets/Profile\\21.png', // Fallback
        'locations[user_address]':
            (address.trim().isEmpty
                ? (currentUser?['user_address'] ?? '')
                : address),
        'locations[user_postcode]':
            (postcode.trim().isEmpty
                ? (currentUser?['user_postcode'] ?? '')
                : postcode),
        'locations[user_state]':
            (state.trim().isEmpty ? (currentUser?['user_state'] ?? '') : state),
        'locations[user_city]':
            (city.trim().isEmpty ? (currentUser?['user_city'] ?? '') : city),
        'locations[user_country]':
            (country.trim().isEmpty
                ? (currentUser?['user_country'] ?? '')
                : country),
        'interest[user_interest]':
            (interests.trim().isEmpty
                ? (currentUser?['user_interest'] ?? '')
                : interests),
        // Credentials: include only if provided to avoid unintended resets
      };
      if (email.trim().isNotEmpty) {
        body['credentials[user_email]'] = email;
      }
      if (phone.trim().isNotEmpty) {
        body['credentials[user_phone]'] = phone;
      }
      // Preferences: use provided overrides when present, otherwise fallback to current
      body['preferences[pref_gender]'] =
          (prefGender != null && prefGender.trim().isNotEmpty)
              ? prefGender
              : (currentPrefs?['pref_gender'] ?? 'male');
      body['preferences[pref_age_min]'] =
          ((prefAgeMin ?? (currentPrefs?['pref_age_min'] ?? 18))).toString();
      body['preferences[pref_age_max]'] =
          ((prefAgeMax ?? (currentPrefs?['pref_age_max'] ?? 80))).toString();
      body['preferences[pref_location]'] =
          ((prefLocation ?? (currentPrefs?['pref_location'] ?? 50))).toString();

      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      print('Update profile failed: ${response.statusCode} ${response.body}');
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
