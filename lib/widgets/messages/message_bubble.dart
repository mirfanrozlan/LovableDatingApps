import 'package:flutter/material.dart';
import '../../themes/theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool largeEmoji;
  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.largeEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppTheme.primary : Colors.white;
    final fg = isMe ? Colors.white : Colors.black;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMe ? 12 : 2),
      bottomRight: Radius.circular(isMe ? 2 : 12),
    );
    String two(int n) => n < 10 ? '0$n' : '$n';
    final dt = timestamp.toLocal();
    final dateStr =
        '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
            top: 6,
            bottom: 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: largeEmoji ? 18 : 12,
            vertical: largeEmoji ? 16 : 8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(color: Color(0x10000000), blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: largeEmoji ? 40 : 14,
                  height: largeEmoji ? 1.2 : 1.4,
                ),
              ),
              const SizedBox(height: 4),
              if (!largeEmoji)
                Text(
                  dateStr,
                  style: TextStyle(
                    color: (isMe ? Colors.white70 : Colors.black54),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
