import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';

class CallingView extends StatelessWidget {
  const CallingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF0C1B2A)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Calling Emma...', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 40),
            const CircleAvatar(radius: 60),
            const SizedBox(height: 20),
            const Text('00:01', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.volume_off, color: Colors.white)),
              SizedBox(width: 24),
              CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.call_end, color: Colors.white)),
              SizedBox(width: 24),
              CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.mic_off, color: Colors.white)),
            ]),
          ],
        ),
      ),
    );
  }
}