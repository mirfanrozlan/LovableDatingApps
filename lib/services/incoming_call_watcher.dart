import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../controllers/calls/incoming_call_controller.dart';

/// Watches Firestore for incoming call rooms
/// Acts as a backup mechanism if FCM fails
class IncomingCallWatcher {
  static final IncomingCallWatcher instance = IncomingCallWatcher._();
  IncomingCallWatcher._();

  final _storage = const FlutterSecureStorage();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// Start watching for incoming calls
  Future<void> start() async {
    try {
      final idStr = await _storage.read(key: 'user_id');
      final uid = int.tryParse(idStr ?? '');
      
      if (uid == null) {
        if (kDebugMode) {
          print('[IncomingCallWatcher] No user ID found, cannot start watching');
        }
        return;
      }

      // Cancel existing subscription
      await _subscription?.cancel();

      // Watch for rooms where this user is the callee and offer exists
      _subscription = FirebaseFirestore.instance
          .collection('rooms')
          .where('callee_id', isEqualTo: uid)
          .where('offer', isNotEqualTo: null)
          .snapshots()
          .listen(
        (snapshot) {
          try {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data();
                if (data == null) continue;

                // Skip if already answered or rejected
                final answered = data['answer'] != null;
                final rejected = data['rejected'] == true;
                final cancelled = data['cancelled'] == true || data['hangup'] == true;

                if (answered || rejected || cancelled) {
                  continue;
                }

                // Extract call information
                final roomId = change.doc.id;
                final callerName = (data['caller_name'] ?? 'Unknown') as String;
                final callerId = (data['caller_id'] ?? '').toString();
                final avatar = data['caller_avatar'] as String?;
                final isVideo = (data['video'] == true);

                if (kDebugMode) {
                  print('[IncomingCallWatcher] New incoming call detected: $roomId');
                }

                // Start ringing
                IncomingCallController.instance.startRinging(
                  callerName: callerName,
                  callUuid: roomId,
                  callerId: callerId,
                  avatarUrl: avatar,
                  isVideo: isVideo,
                );
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('[IncomingCallWatcher] Error processing snapshot: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('[IncomingCallWatcher] Stream error: $error');
            print('[IncomingCallWatcher] This is usually a network connectivity issue.');
            print('[IncomingCallWatcher] FCM notifications will still work independently.');
          }
          // Don't throw - let FCM handle notifications
          // Firestore watcher is just a backup mechanism
        },
        cancelOnError: false, // Keep listening even on errors
      );

      if (kDebugMode) {
        print('[IncomingCallWatcher] Started watching for user: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IncomingCallWatcher] Error starting watcher: $e');
      }
    }
  }

  /// Stop watching for incoming calls
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    
    if (kDebugMode) {
      print('[IncomingCallWatcher] Stopped watching');
    }
  }
}
