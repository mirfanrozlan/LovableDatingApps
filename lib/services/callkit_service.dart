import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import '../controllers/calls/incoming_call_controller.dart';
import 'package:uuid/uuid.dart';

/// Service for managing CallKit incoming call notifications
/// Handles native call UI display and user actions (accept/reject)
class CallKitService {
  static final _uuid = const Uuid();
  static StreamSubscription<CallEvent?>? _eventSubscription;
  static bool _isInitialized = false;

  /// Initialize CallKit service and set up event listeners
  static Future<void> setup() async {
    if (kIsWeb || _isInitialized) return;

    try {
      // Cancel existing subscription if any
      await _eventSubscription?.cancel();

      // Listen to CallKit events (accept, decline, timeout, etc.)
      _eventSubscription = FlutterCallkitIncoming.onEvent.listen((event) async {
        if (event != null) {
          await _handleCallKitEvent(event);
        }
      });

      _isInitialized = true;
      if (kDebugMode) {
        print('[CallKit] Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CallKit] Setup error: $e');
      }
    }
  }

  /// Handle CallKit events (accept, decline, timeout)
  static Future<void> _handleCallKitEvent(CallEvent event) async {
    try {
      if (kDebugMode) {
        print('[CallKit] Event received: ${event.event}');
        print('[CallKit] Event body: ${event.body}');
      }

      final body = event.body ?? {};
      final extra = (body['extra'] as Map?)?.cast<dynamic, dynamic>() ?? {};
      
      // Extract call information
      final callUuid = body['id']?.toString() ?? extra['call_uuid']?.toString() ?? '';
      final roomId = extra['room_id']?.toString() ?? callUuid;
      final isVideo = extra['isVideo'] == true || extra['call_type'] == 'video';
      
      // Normalize event name
      final eventName = event.event.toString().toUpperCase();
      
      switch (eventName) {
        case 'ACTION_CALL_ACCEPT':
        case 'CALL_ACCEPT':
          if (kDebugMode) {
            print('[CallKit] Call accepted: $roomId');
          }
          IncomingCallController.instance.setIsVideo(isVideo);
          await IncomingCallController.instance.acceptFromCallKit(roomId);
          break;

        case 'ACTION_CALL_DECLINE':
        case 'ACTION_CALL_ENDED':
        case 'ACTION_CALL_TIMEOUT':
        case 'CALL_DECLINE':
        case 'CALL_ENDED':
        case 'CALL_TIMEOUT':
          if (kDebugMode) {
            print('[CallKit] Call declined/ended: $roomId');
          }
          IncomingCallController.instance.setIsVideo(isVideo);
          await IncomingCallController.instance.declineFromCallKit(roomId);
          break;

        default:
          if (kDebugMode) {
            print('[CallKit] Unhandled event: $eventName');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CallKit] Event handling error: $e');
      }
    }
  }

  /// Request necessary permissions for CallKit
  static Future<void> requestPermissions() async {
    if (kIsWeb) return;

    try {
      // Request notification permission
      await FlutterCallkitIncoming.requestNotificationPermission({
        'title': 'Notification Permission',
        'rationaleMessagePermission':
            'Notification permission is required to show incoming call notifications.',
        'postNotificationMessageRequired':
            'Notification permission is required. Please allow notification permission from settings.',
      });

      // Request full-screen intent permission (Android 12+)
      final canUseFullScreenIntent = await FlutterCallkitIncoming.canUseFullScreenIntent();
      if (canUseFullScreenIntent != true) {
        await FlutterCallkitIncoming.requestFullIntentPermission();
      }

      if (kDebugMode) {
        print('[CallKit] Permissions requested');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CallKit] Permission request error: $e');
      }
    }
  }

  /// Show incoming call notification with native CallKit UI
  /// 
  /// [callerName] - Name of the caller
  /// [callUuid] - Unique identifier for the call (used as room_id)
  /// [callerId] - ID of the caller
  /// [avatarUrl] - Optional avatar URL
  /// [isVideo] - Whether this is a video call
  /// [durationMs] - Call timeout duration in milliseconds (default: 30 seconds)
  static Future<void> showIncoming({
    required String callerName,
    required String callUuid,
    required String callerId,
    String? avatarUrl,
    bool isVideo = false,
    int durationMs = 30000,
  }) async {
    if (kIsWeb) return;

    try {
      final id = callUuid.isEmpty ? _uuid.v4() : callUuid;

      final params = CallKitParams(
        id: id,
        nameCaller: callerName,
        appName: 'LoveConnect',
        avatar: avatarUrl,
        type: isVideo ? 1 : 0, // 0 = audio, 1 = video
        duration: durationMs,
        textAccept: 'Accept',
        textDecline: 'Decline',
        extra: <String, dynamic>{
          'room_id': callUuid,
          'call_uuid': callUuid,
          'caller_id': callerId,
          'isVideo': isVideo,
          'call_type': isVideo ? 'video' : 'audio',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0C1B2A',
          actionColor: '#4CAF50',
        ),
        ios: IOSParams(
          supportsVideo: true,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);

      if (kDebugMode) {
        print('[CallKit] Incoming call shown: $id ($callerName)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CallKit] Show incoming error: $e');
      }
      rethrow;
    }
  }

  /// End/dismiss an incoming call notification
  /// 
  /// [callUuid] - UUID of the call to end. If empty, ends all calls.
  static Future<void> endCall(String callUuid) async {
    if (kIsWeb) return;

    try {
      if (callUuid.isEmpty) {
        await FlutterCallkitIncoming.endAllCalls();
        if (kDebugMode) {
          print('[CallKit] All calls ended');
        }
      } else {
        await FlutterCallkitIncoming.endCall(callUuid);
        if (kDebugMode) {
          print('[CallKit] Call ended: $callUuid');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CallKit] End call error: $e');
      }
    }
  }

  /// Cleanup resources
  static Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _isInitialized = false;
  }
}
