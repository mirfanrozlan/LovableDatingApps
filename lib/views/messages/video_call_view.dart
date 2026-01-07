import 'package:flutter/material.dart';
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

class _VideoCallViewState extends State<VideoCallView> with WidgetsBindingObserver {
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
          _showStatus = true;
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _statusText = 'Connected';
          _showStatus = true;
          _setBusy(true);
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
    _signaling.onRemoteHangUp = () {
      if (!mounted) return;
      _setBusy(false);
      Navigator.pop(context);
    };

    final busy = await _isOtherBusy();
    if (busy) {
      if (!mounted) return;
      setState(() {
        _statusText = 'User is busy';
        _showStatus = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    await _signaling.openMedia(_localRenderer, _remoteRenderer);

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final snap = await roomRef.get();
    if (snap.exists && (snap.data()?['offer'] != null)) {
      await _signaling.joinRoom(roomId);
    } else {
      final id = await _signaling.createRoom(roomId);
      _roomId = id;
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setBusy(false);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _signaling.enterBackground();
    } else if (state == AppLifecycleState.resumed) {
      _signaling.exitBackground();
    }
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
      await FirebaseFirestore.instance.collection('users').doc(mid).set(
        {'busy': busy},
        SetOptions(merge: true),
      );
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
            child: _showStatus
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
