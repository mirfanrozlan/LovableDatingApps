import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../services/signaling.dart';

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is ChatSummaryModel ? rawArgs : null;
    final storage = const FlutterSecureStorage();
    final meStr = await storage.read(key: 'user_id');
    final meId = int.tryParse(meStr ?? '');
    if (rawArgs is Map && rawArgs['roomId'] is String) {
      _roomId = rawArgs['roomId'] as String;
    } else {
      final otherId = int.tryParse(args?.id ?? '');
      if (meId == null || otherId == null) {
        setState(() => _initialized = true);
        return;
      }
      final a = meId <= otherId ? meId : otherId;
      final b = meId <= otherId ? otherId : meId;
      final roomId = 'vc_${a}_$b';
      _roomId = roomId;
    }

    _signaling.onPeerConnectionState = (state) {
      if (!mounted) return;
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _statusText = 'Connection failed';
          _showStatus = true;
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _statusText = 'Connected';
          _showStatus = true;
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

    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(_roomId!);
    final snap = await roomRef.get();
    if (snap.exists && (snap.data()?['offer'] != null)) {
      await _signaling.joinRoom(_roomId!);
    }
    // else {
    //   final id = await _signaling.createRoom(_roomId!);
    //   _roomId = id;
    // }
    _roomSub = roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        setState(() => _statusText = 'Call ended');
        await _signaling.hangUp(_localRenderer);
        if (mounted) Navigator.pop(context);
      }
    });

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _signaling.hangUp(_localRenderer);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _endCall(BuildContext context) async {
    await _signaling.hangUp(_localRenderer);
    Navigator.pop(context);
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
    return AppScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child:
                _initialized
                    ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                    : Container(color: Colors.black),
          ),
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child:
                _showStatus
                    ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _roomId != null ? _statusText : 'Preparing...',
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
          Positioned(
            top: 80,
            right: 16,
            child: Container(
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
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
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
      ),
    );
  }
}
