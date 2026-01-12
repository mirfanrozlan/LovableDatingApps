import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/signaling.dart';
import '../../services/callkit_service.dart';
import '../../routes.dart';
import '../../navigation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Controller for managing incoming call state and lifecycle
/// Handles ringing, acceptance, rejection, and timeout
class IncomingCallController extends ChangeNotifier {
  static final IncomingCallController instance = IncomingCallController._();
  IncomingCallController._();

  final Signaling _signaling = Signaling();
  final _storage = const FlutterSecureStorage();

  // State variables
  bool _isRinging = false;
  String? _callUuid;
  String? _roomId;
  String? _callerName;
  String? _callerId;
  String? _avatarUrl;
  bool _isVideo = false;
  Timer? _timeoutTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;

  // Getters
  bool get isRinging => _isRinging;
  String? get callUuid => _callUuid;
  String? get roomId => _roomId;
  String? get callerName => _callerName;
  String? get callerId => _callerId;
  String? get avatarUrl => _avatarUrl;
  bool get isVideo => _isVideo;

  /// Set video call flag
  void setIsVideo(bool value) {
    _isVideo = value;
  }

  /// Start ringing for an incoming call
  /// Called when FCM notification is received or Firestore room is detected
  Future<void> startRinging({
    required String callerName,
    required String callUuid,
    required String callerId,
    String? avatarUrl,
    bool isVideo = false,
  }) async {
    // Prevent duplicate ringing
    if (_isRinging && _callUuid == callUuid) {
      if (kDebugMode) {
        print('[IncomingCall] Already ringing for call: $callUuid');
      }
      return;
    }

    // Stop any existing call
    if (_isRinging) {
      await _stopRinging();
    }

    _callerName = callerName;
    _callUuid = callUuid;
    _roomId = callUuid; // room_id is same as call_uuid
    _callerId = callerId;
    _avatarUrl = avatarUrl;
    _isVideo = isVideo;
    _isRinging = true;
    notifyListeners();

    if (kDebugMode) {
      print('[IncomingCall] Starting ring: $callUuid from $callerName');
    }

    try {
      // Show CallKit incoming call UI
      await CallKitService.showIncoming(
        callerName: callerName,
        callUuid: callUuid,
        callerId: callerId,
        avatarUrl: avatarUrl,
        isVideo: isVideo,
        durationMs: 30000, // 30 seconds timeout
      );

      // Monitor room state for cancellation/end
      _roomSubscription = FirebaseFirestore.instance
          .collection('rooms')
          .doc(callUuid)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          if (kDebugMode) {
            print('[IncomingCall] Room deleted, stopping ring');
          }
          _stopRinging();
          return;
        }

        final data = snapshot.data();
        if (data == null) return;

        // Check if call was answered, rejected, or cancelled
        final answered = data['answer'] != null;
        final rejected = data['rejected'] == true;
        final cancelled = data['cancelled'] == true || data['hangup'] == true || data['ended'] == true;
        final offerRemoved = data['offer'] == null;

        if (answered || rejected || cancelled || offerRemoved) {
          if (kDebugMode) {
            print('[IncomingCall] Call ended (answered: $answered, rejected: $rejected, cancelled: $cancelled)');
          }
          _stopRinging();
        }
      });

      // Set timeout to auto-decline after 30 seconds
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (kDebugMode) {
          print('[IncomingCall] Timeout reached, auto-declining');
        }
        decline();
      });
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCall] Start ringing error: $e');
      }
      _stopRinging();
    }
  }

  /// Accept call from CallKit notification
  /// Called when user taps "Accept" on native call UI
  Future<void> acceptFromCallKit(String roomId) async {
    if (!_isRinging) {
      if (kDebugMode) {
        print('[IncomingCall] Not ringing, ignoring accept');
      }
      return;
    }

    if (kDebugMode) {
      print('[IncomingCall] Accepting call from CallKit: $roomId');
    }

    await _acceptCall(roomId);
  }

  /// Accept call from in-app UI
  /// Called when user taps "Accept" on in-app incoming call screen
  Future<void> acceptFromApp(BuildContext context) async {
    if (!_isRinging || _roomId == null) {
      if (kDebugMode) {
        print('[IncomingCall] Not ringing or no room ID, ignoring accept');
      }
      return;
    }

    if (kDebugMode) {
      print('[IncomingCall] Accepting call from app: $_roomId');
    }

    await _acceptCall(_roomId!);
    
    // Navigate to call screen
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(
        _isVideo ? AppRoutes.videoCall : AppRoutes.call,
      );
    }
  }

  /// Internal method to handle call acceptance
  Future<void> _acceptCall(String roomId) async {
    try {
      // Stop ringing
      await _stopRinging();

      // Notify backend that call was accepted
      await _notifyBackendCallAccepted(roomId);

      // Open media (camera/microphone)
      await _signaling.openMedia(
        RTCVideoRenderer(),
        RTCVideoRenderer(),
        video: _isVideo,
        audio: true,
      );

      // Join the room using caller's offer
      await _signaling.joinRoom(roomId);

      // Navigate to call screen using navigator key
      appNavigatorKey.currentState?.pushReplacementNamed(
        _isVideo ? AppRoutes.videoCall : AppRoutes.call,
      );

      if (kDebugMode) {
        print('[IncomingCall] Call accepted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCall] Accept call error: $e');
      }
      // Show error to user (if context is available)
      final context = appNavigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
    }
  }

  /// Decline call from CallKit notification
  /// Called when user taps "Decline" or call times out
  Future<void> declineFromCallKit(String roomId) async {
    if (kDebugMode) {
      print('[IncomingCall] Declining call from CallKit: $roomId');
    }
    await _declineCall(roomId);
  }

  /// Decline call from in-app UI
  /// Called when user taps "Decline" on in-app incoming call screen
  Future<void> declineFromApp() async {
    if (!_isRinging || _roomId == null) {
      if (kDebugMode) {
        print('[IncomingCall] Not ringing or no room ID, ignoring decline');
      }
      return;
    }

    if (kDebugMode) {
      print('[IncomingCall] Declining call from app: $_roomId');
    }
    await _declineCall(_roomId!);
  }

  /// Decline call (public method)
  Future<void> decline() async {
    if (!_isRinging || _roomId == null) return;
    await _declineCall(_roomId!);
  }

  /// Internal method to handle call rejection
  Future<void> _declineCall(String roomId) async {
    try {
      // Stop ringing
      await _stopRinging();

      // Notify backend that call was rejected
      await _notifyBackendCallRejected(roomId);

      // Mark room as rejected and delete it
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'rejected': true,
      }, SetOptions(merge: true));

      await Future.delayed(const Duration(milliseconds: 200));
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();

      if (kDebugMode) {
        print('[IncomingCall] Call declined successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCall] Decline call error: $e');
      }
    }
  }

  /// Stop ringing and clean up resources
  Future<void> _stopRinging() async {
    if (!_isRinging) return;

    try {
      // Cancel timeout
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      // Cancel room subscription
      await _roomSubscription?.cancel();
      _roomSubscription = null;

      // End CallKit notification
      if (_callUuid != null) {
        await CallKitService.endCall(_callUuid!);
      }

      // Clear state
      _isRinging = false;
      final oldCallUuid = _callUuid;
      _callUuid = null;
      _roomId = null;
      _callerName = null;
      _callerId = null;
      _avatarUrl = null;
      _isVideo = false;

      notifyListeners();

      if (kDebugMode) {
        print('[IncomingCall] Ringing stopped: $oldCallUuid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCall] Stop ringing error: $e');
      }
    }
  }

  /// Notify backend that call was accepted
  Future<void> _notifyBackendCallAccepted(String roomId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final userId = await _storage.read(key: 'user_id');
      if (userId == null) return;

      final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/notify/call-accepted');
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'room_id': roomId,
          'user_id': userId,
        }),
      );

      if (kDebugMode) {
        print('[IncomingCall] Backend notified: call accepted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCall] Backend notification error: $e');
      }
    }
  }

  /// Notify backend that call was rejected
  Future<void> _notifyBackendCallRejected(String roomId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final userId = await _storage.read(key: 'user_id');
      if (userId == null) return;

      final uri = Uri.https('demo.mazri-minecraft.xyz', '/api/notify/call-rejected');
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'room_id': roomId,
          'user_id': userId,
        }),
      );

      if (kDebugMode) {
        print('[IncomingCall] Backend notified: call rejected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCall] Backend notification error: $e');
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }
}
