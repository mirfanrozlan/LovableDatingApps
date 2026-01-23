import 'package:flutter/material.dart';
import 'routes.dart';
import 'themes/theme.dart';
import 'controllers/app/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/callkit_service.dart';
import 'controllers/calls/incoming_call_controller.dart';
import 'services/incoming_call_watcher.dart';
import 'navigation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

/// Background FCM message handler
/// This runs in a separate isolate when app is terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CallKitService.setup();

  if (kDebugMode) {
    print('[FCM Background] Message received: ${message.messageId}');
    print('[FCM Background] Data: ${message.data}');
  }

  // Handle incoming call in background
  await _handleIncomingCallMessage(message.data);
}

/// Handle incoming call FCM message
Future<void> _handleIncomingCallMessage(Map<String, dynamic> data) async {
  try {
    final type = data['type']?.toString() ?? '';

    if (type == 'incoming_call' ||
        type == 'incoming_video_call' ||
        data.containsKey('call_uuid')) {
      final callUuid =
          data['call_uuid']?.toString() ??
          data['room_id']?.toString() ??
          data['uuid']?.toString() ??
          '';
      final callerName =
          data['caller_name']?.toString() ??
          data['callerName']?.toString() ??
          data['sender_name']?.toString() ??
          data['name']?.toString() ??
          'Unknown';
      final callerId =
          data['caller_id']?.toString() ?? data['callerId']?.toString() ?? '';
      final avatarUrl =
          data['avatar']?.toString() ??
          data['callerAvatar']?.toString() ??
          data['caller_avatar']?.toString();
      final isVideo =
          type == 'incoming_video_call' ||
          data['call_type'] == 'video' ||
          (data['video'] == true) ||
          (data['callType']?.toString() == '1');

      if (callUuid.isEmpty) {
        if (kDebugMode) {
          print('[FCM] Missing call_uuid, ignoring');
        }
        return;
      }

      // Start ringing
      IncomingCallController.instance.startRinging(
        callerName: callerName,
        callUuid: callUuid,
        callerId: callerId,
        avatarUrl: avatarUrl,
        isVideo: isVideo,
      );

      if (kDebugMode) {
        print('[FCM] Incoming call handled: $callUuid from $callerName');
      }
    } else if (type == 'call_cancelled' || type == 'incoming_call_cancelled') {
      final callUuid =
          data['call_uuid']?.toString() ??
          data['room_id']?.toString() ??
          data['uuid']?.toString() ??
          '';

      if (callUuid.isNotEmpty) {
        await CallKitService.endCall(callUuid);
        if (kDebugMode) {
          print('[FCM] Call cancelled: $callUuid');
        }
      }
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('[FCM Handler] Error handling message: $e');
      print('[FCM Handler] Stack trace: $stackTrace');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request FCM permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    sound: true,
    badge: true,
    provisional: false,
  );

  // Configure foreground notification presentation
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize CallKit
  await CallKitService.requestPermissions();
  await CallKitService.setup();

  // Start Firestore watcher for incoming calls (backup mechanism)
  // This is non-blocking - if it fails, FCM will still work
  try {
    await IncomingCallWatcher.instance.start();
  } catch (e) {
    if (kDebugMode) {
      print('[Main] Firestore watcher failed to start: $e');
      print('[Main] FCM notifications will still work independently.');
    }
    // Continue - FCM is the primary notification mechanism
  }

  // Handle FCM messages when app is in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (kDebugMode) {
      print('[FCM Foreground] Message received: ${message.messageId}');
      print('[FCM Foreground] Data: ${message.data}');
    }

    await _handleIncomingCallMessage(message.data);
  });

  // Handle FCM messages when app is opened from terminated state
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    if (kDebugMode) {
      print('[FCM Initial] App opened from terminated state');
      print('[FCM Initial] Data: ${initialMessage.data}');
    }
    await _handleIncomingCallMessage(initialMessage.data);
  }

  // Handle FCM messages when app is opened from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    if (kDebugMode) {
      print('[FCM Opened] App opened from background');
      print('[FCM Opened] Data: ${message.data}');
    }

    await _handleIncomingCallMessage(message.data);

    // Navigate to call screen (use existing calling_view.dart)
    final type = message.data['type']?.toString() ?? '';
    if (type == 'incoming_call' ||
        type == 'incoming_video_call' ||
        message.data.containsKey('call_uuid')) {
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        final callUuid =
            message.data['call_uuid']?.toString() ??
            message.data['room_id']?.toString() ??
            message.data['uuid']?.toString() ??
            '';
        final isVideo =
            type == 'incoming_video_call' ||
            message.data['call_type'] == 'video' ||
            (message.data['video'] == true) ||
            (message.data['video'] == 'true') ||
            (message.data['callType']?.toString() == '1');

        // Navigate to appropriate call view with roomId
        if (callUuid.isNotEmpty) {
          if (isVideo) {
            nav.pushNamed(
              AppRoutes.videoCall,
              arguments: {'roomId': callUuid, 'isIncoming': true},
            );
          } else {
            nav.pushNamed(
              AppRoutes.call,
              arguments: {'roomId': callUuid, 'isIncoming': true},
            );
          }
        }
      }
    }
  });

  // Run app
  runApp(
    ChangeNotifierProvider.value(
      value: IncomingCallController.instance,
      child: const LoveConnectApp(),
    ),
  );
}

class LoveConnectApp extends StatefulWidget {
  const LoveConnectApp({super.key});

  @override
  State<LoveConnectApp> createState() => _LoveConnectAppState();
}

class _LoveConnectAppState extends State<LoveConnectApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkActiveCall();
    }
  }

  void _checkActiveCall() {
    final controller = IncomingCallController.instance;
    if (controller.activeCallRoomId != null) {
      if (kDebugMode) {
        print(
          '[LoveConnectApp] App resumed. Active call: ${controller.activeCallRoomId}',
        );
      }

      final current = appRouteObserver.currentRoute;
      if (current != AppRoutes.call && current != AppRoutes.videoCall) {
        if (kDebugMode) {
          print('[LoveConnectApp] Restoring call view. Current: $current');
        }
        final nav = appNavigatorKey.currentState;
        if (nav != null) {
          if (controller.activeCallIsVideo) {
            nav.pushNamed(
              AppRoutes.videoCall,
              arguments: {
                'roomId': controller.activeCallRoomId,
                'isIncoming': true,
              },
            );
          } else {
            nav.pushNamed(
              AppRoutes.call,
              arguments: {
                'roomId': controller.activeCallRoomId,
                'isIncoming': true,
              },
            );
          }
        }
      } else {
        if (kDebugMode) {
          print('[LoveConnectApp] Already on call view');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        return MaterialApp(
          title: 'LoveConnect',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.splash,
          navigatorKey: appNavigatorKey,
          navigatorObservers: [appRouteObserver],
        );
      },
    );
  }
}
