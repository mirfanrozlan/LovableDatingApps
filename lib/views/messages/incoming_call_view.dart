import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/calls/incoming_call_controller.dart';

/// In-app incoming call screen
/// Shows caller information and accept/reject buttons
/// This is shown when app is in foreground
class IncomingCallView extends StatelessWidget {
  const IncomingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Consumer<IncomingCallController>(
          builder: (context, controller, _) {
            if (!controller.isRinging) {
              // Call ended or not ringing, go back
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                const Spacer(),
                
                // Avatar
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: controller.avatarUrl != null && controller.avatarUrl!.isNotEmpty
                      ? NetworkImage(controller.avatarUrl!)
                      : null,
                  child: controller.avatarUrl == null || controller.avatarUrl!.isEmpty
                      ? Text(
                          controller.callerName?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(height: 32),
                
                // Caller name
                Text(
                  controller.callerName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Call type
                Text(
                  controller.isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
                
                const Spacer(),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline button
                    _ActionButton(
                      icon: Icons.call_end,
                      label: 'Decline',
                      color: Colors.red,
                      onPressed: () => controller.declineFromApp(),
                    ),
                    
                    // Accept button
                    _ActionButton(
                      icon: controller.isVideo ? Icons.videocam : Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onPressed: () => controller.acceptFromApp(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Action button widget for accept/decline
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 32),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
