import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/controllers/calls/incoming_call_controller.dart';
import '../../widgets/common/app_scaffold.dart';
import 'package:flutter/services.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../controllers/messages/messages_controller.dart';
import '../../services/signaling.dart';
import '../../controllers/calls/incoming_call_controller.dart';

import '../../services/callkit_service.dart';

class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  final _signaling = Signaling();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _initialized = false;
  String? _roomId;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  String _statusText = 'Preparing...';
  bool _showStatus = true;
  StreamSubscription? _roomSub;
  static const _pipChannel = MethodChannel('app.pip');
  bool _inPipMode = false;

  // Timer
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  String? _remoteName;
  String? _remoteAvatarUrl;

  @override
  void initState() {
    super.initState();
    _pipChannel.setMethodCallHandler((call) async {
      if (call.method == 'pipModeChanged') {
        final args = call.arguments as Map;
        if (mounted) {
          setState(() {
            _inPipMode = args['isInPipMode'] as bool;
          });
        }
      }
    });
    _enableAutoPip();
    _init();
  }

  Future<void> _enableAutoPip() async {
    try {
      await _pipChannel.invokeMethod('setAutoPip', {
        'enabled': true,
        'width': 9,
        'height': 16,
      });
    } catch (_) {}
  }

  Future<void> _disableAutoPip() async {
    try {
      await _pipChannel.invokeMethod('setAutoPip', {
        'enabled': false,
        'width': 9,
        'height': 16,
      });
    } catch (_) {}
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Android 12+ handles auto-pip via setAutoEnterEnabled
      // For older versions, we might need to manually trigger enterPictureInPictureMode
      // But for now, we rely on the channel configuration.
    }
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling.onAddRemoteStream = (stream) {
      if (!mounted) return;
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    bool isCaller = false;
    ChatSummaryModel? chatModel;
    int callType = 1;

    if (rawArgs is Map) {
      if (rawArgs['roomId'] is String) _roomId = rawArgs['roomId'] as String;
      if (rawArgs['isCaller'] == true) isCaller = true;
      if (rawArgs['chat'] is ChatSummaryModel) {
        chatModel = rawArgs['chat'] as ChatSummaryModel;
      }
      if (rawArgs['type'] is int) callType = rawArgs['type'] as int;
    } else if (rawArgs is Map && rawArgs['roomId'] is String) {
      // Legacy support for IncomingCallController which sends {roomId, isIncoming}
      _roomId = rawArgs['roomId'] as String;
    }

    _signaling.onPeerConnectionState = (state) {
      if (!mounted) return;
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _statusText = 'Connection failed';
          _showStatus = true;
          _callTimer?.cancel();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _statusText = 'Connected';
          _showStatus = true;
          _startTimer();
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            setState(() {
              _showStatus = false;
            });
          });
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          _statusText = 'Connecting...';
          _showStatus = true;
        }
      });
    };
    _signaling.onIceConnectionState = (state) {
      if (!mounted) return;
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        setState(() {
          _statusText = 'Connection failed';
          _showStatus = true;
        });
      }
    };

    await _signaling.openMedia(_localRenderer, _remoteRenderer);

    if (isCaller && _roomId != null) {
      // Create room and notify callee
      await _signaling.createRoom(_roomId!);

      if (chatModel != null && chatModel.id != null) {
        // Send notification to callee
        // Note: passing chatModel.name as callerName because ChatView did so.
        // Ideally this should be current user's name.
        await MessagesController().startIncomingCall(
          calleeUserId: int.tryParse(chatModel.id!) ?? 0,
          uuid: _roomId!,
          callerName: chatModel.name,
          callerHandle: chatModel.id!,
          callerAvatar: chatModel.avatarUrl,
          callType: callType,
        );
      }
    } else if (_roomId != null) {
      final roomRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(_roomId!);
      final snap = await roomRef.get();
      if (snap.exists && (snap.data()?['offer'] != null)) {
        await _signaling.joinRoom(_roomId!);
      }
    }

    if (_roomId != null) {
      final roomRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(_roomId!);
      _roomSub = roomRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) {
          if (mounted) {
            setState(() {
              _statusText = 'Call ended';
              _showStatus = true;
            });
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              await _signaling.hangUp(_localRenderer, remoteHangup: true);
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          }
        }
      });
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    // If in PiP mode when call ends, close PiP (minimize app)
    if (_inPipMode) {
      _pipChannel.invokeMethod('closePip');
    }
    _disableAutoPip();
    // End the active CallKit session
    if (_roomId != null) {
      // We don't await here to avoid blocking dispose
      CallKitService.endCall(_roomId!);
    }

    if (_roomId != null &&
        IncomingCallController.instance.activeCallRoomId == _roomId) {
      IncomingCallController.instance.clearActiveCall();
    }
    _roomSub?.cancel();
    _signaling.hangUp(_localRenderer);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _endCall(BuildContext context) async {
    _roomSub?.cancel();
    try {
      await _signaling.hangUp(_localRenderer);
    } catch (_) {}
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    final stream = _signaling.LocalStream;
    if (stream != null) {
      for (final t in stream.getAudioTracks()) {
        t.enabled = !_muted;
      }
    }
  }

  void _toggleCamera() {
    setState(() => _cameraOff = !_cameraOff);
    final stream = _signaling.LocalStream;
    if (stream != null) {
      for (final t in stream.getVideoTracks()) {
        t.enabled = !_cameraOff;
      }
    }
  }

  void _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Positioned.fill(
          child:
              _initialized
                  ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                  : Container(color: Colors.black),
        ),
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: Column(
            children: [
              if (_showStatus && !_inPipMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_roomId != null ? _statusText : 'Preparing...'),
                ),
              if (!_showStatus && !_inPipMode && _callDuration != Duration.zero)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 80,
          right: 16,
          child:
              _inPipMode
                  ? const SizedBox.shrink()
                  : Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0x30000000), blurRadius: 8),
                      ],
                    ),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child:
              _inPipMode
                  ? const SizedBox.shrink()
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: IconButton(
                          icon: Icon(
                            _speakerOn ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleSpeaker,
                        ),
                      ),
                      const SizedBox(width: 24),
                      CircleAvatar(
                        backgroundColor: Colors.red,
                        child: IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.white),
                          onPressed: () => _endCall(context),
                        ),
                      ),
                      const SizedBox(width: 24),
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: IconButton(
                          icon: Icon(
                            _muted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                      const SizedBox(width: 24),
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: IconButton(
                          icon: Icon(
                            _cameraOff ? Icons.videocam_off : Icons.videocam,
                            color: Colors.white,
                          ),
                          onPressed: _toggleCamera,
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );

    if (_inPipMode) {
      return Scaffold(body: content);
    }

    return AppScaffold(child: content);
  }
}
