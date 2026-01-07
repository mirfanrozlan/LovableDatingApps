import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../services/signaling.dart';

class CallingView extends StatefulWidget {
  const CallingView({super.key});

  @override
  State<CallingView> createState() => _CallingViewState();
}

class _CallingViewState extends State<CallingView> with WidgetsBindingObserver {
  final _signaling = Signaling();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _initialized = false;
  String? _roomId;
  bool _muted = false;
  String _statusText = 'Connecting...';
  bool _speakerOn = true;
  Timer? _callTimer;
  int _seconds = 0;
  int? _meId;
  int? _otherId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final args =
        ModalRoute.of(context)?.settings.arguments as ChatSummaryModel?;
    final storage = const FlutterSecureStorage();
    final meStr = await storage.read(key: 'user_id');
    _meId = int.tryParse(meStr ?? '');
    _otherId = int.tryParse(args?.id ?? '');
    if (_meId == null || _otherId == null) {
      setState(() => _initialized = true);
      return;
    }
    final a = _meId! <= _otherId! ? _meId! : _otherId!;
    final b = _meId! <= _otherId! ? _otherId! : _meId!;
    final roomId = 'vc_${a}_$b';
    _roomId = roomId;

    _signaling.onPeerConnectionState = (state) {
      if (!mounted) return;
      setState(() {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _statusText = 'Connection failed';
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _statusText = 'Connected';
          _startTimer();
          _setBusy(true);
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
    _signaling.onRemoteHangUp = () {
      if (!mounted) return;
      _stopTimer();
      _setBusy(false);
      Navigator.pop(context);
    };

    final busy = await _isOtherBusy();
    if (busy) {
      if (!mounted) return;
      setState(() => _statusText = 'User is busy');
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    await _signaling.openMedia(
      _localRenderer,
      _remoteRenderer,
      video: false,
      audio: true,
    );

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final snap = await roomRef.get();
    if (snap.exists && (snap.data()?['offer'] != null)) {
      await _signaling.joinRoom(roomId);
    } else {
      await _signaling.createRoom(roomId);
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _setBusy(false);
    _signaling.hangUp(_localRenderer);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _endCall(BuildContext context) async {
    _stopTimer();
    _setBusy(false);
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

  void _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _signaling.enterBackground();
    } else if (state == AppLifecycleState.resumed) {
      _signaling.exitBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    String hh = (_seconds ~/ 3600).toString().padLeft(2, '0');
    String mm = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    String ss = (_seconds % 60).toString().padLeft(2, '0');
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
            Text('$hh:$mm:$ss', style: const TextStyle(color: Colors.white70)),
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

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _seconds = 0;
  }

  Future<bool> _isOtherBusy() async {
    try {
      final oid = _otherId?.toString();
      if (oid == null) return false;
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(oid).get();
      final data = snap.data() ?? {};
      final busy = data['busy'] == true;
      return busy;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setBusy(bool busy) async {
    try {
      final mid = _meId?.toString();
      if (mid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(mid).set({
        'busy': busy,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
