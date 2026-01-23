import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../services/signaling.dart';

class CallingView extends StatefulWidget {
  const CallingView({super.key});

  @override
  State<CallingView> createState() => _CallingViewState();
}

class _CallingViewState extends State<CallingView> {
  final _signaling = Signaling();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  String? _roomId;
  bool _muted = false;
  String _statusText = 'Connecting...';
  bool _speakerOn = true;
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

    if (rawArgs is Map && rawArgs['roomId'] is String) {
      _roomId = rawArgs['roomId'] as String;
    }

    _signaling.onPeerConnectionState = (state) {
      if (!mounted) return;
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _statusText = 'Connection failed';
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _statusText = 'Connected';
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          _statusText = 'Connecting...';
        }
      });
    };
    _signaling.onIceConnectionState = (state) {
      if (!mounted) return;
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        setState(() {
          _statusText = 'Connection failed';
        });
      }
    };

    await _signaling.openMedia(
      _localRenderer,
      _remoteRenderer,
      video: false,
      audio: true,
    );

    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(_roomId!);
    final snap = await roomRef.get();
    if (snap.exists && (snap.data()?['offer'] != null)) {
      await _signaling.joinRoom(_roomId!);
    }

    _roomSub = roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        if (mounted) {
          setState(() => _statusText = 'Call ended');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            await _signaling.hangUp(_localRenderer);
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        }
      }
    });
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
    if (mounted) Navigator.pop(context);
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

  void _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF0C1B2A)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusText, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 40),
            const CircleAvatar(radius: 60),
            const SizedBox(height: 20),
            const Text('00:01', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                      _speakerOn ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleSpeaker,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
