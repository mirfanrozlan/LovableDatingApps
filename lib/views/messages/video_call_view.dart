import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../widgets/common/app_scaffold.dart';

class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  CameraController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    CameraDescription cam = cams.first;
    for (final c in cams) {
      if (c.lensDirection == CameraLensDirection.front) {
        cam = c;
        break;
      }
    }
    final controller = CameraController(cam, ResolutionPreset.medium, enableAudio: true);
    _controller = controller;
    await controller.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _endCall(BuildContext context) async {
    await _controller?.dispose();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done || _controller == null || !_controller!.value.isInitialized) {
                  return Container(color: Colors.black);
                }
                return CameraPreview(_controller!);
              },
            ),
          ),
          Positioned(top: 24, left: 24, right: 24, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)), child: const Text('Starting video call...'))),
          Positioned(top: 80, right: 16, child: Container(width: 100, height: 140, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 8)]), child: (_controller != null && _controller!.value.isInitialized) ? CameraPreview(_controller!) : const Center(child: CircularProgressIndicator()))),
          Positioned(bottom: 40, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.volume_off, color: Colors.white)),
            const SizedBox(width: 24),
            CircleAvatar(backgroundColor: Colors.red, child: IconButton(icon: const Icon(Icons.call_end, color: Colors.white), onPressed: () => _endCall(context))),
            const SizedBox(width: 24),
            const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.mic_off, color: Colors.white)),
          ])),
        ],
      ),
    );
  }
}