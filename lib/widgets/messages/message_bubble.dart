import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isMe 
      ? const Color(0xFF10B981)
      : (isDark ? Colors.white.withOpacity(0.08) : Colors.white);
      
    final fg = isMe 
      ? Colors.white 
      : (isDark ? Colors.white : Colors.black87);

    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 20),
    );

    String two(int n) => n < 10 ? '0$n' : '$n';
    final dt = timestamp.toLocal();
    final dateStr = '${two(dt.hour)}:${two(dt.minute)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: largeEmoji ? 18 : 16,
              vertical: largeEmoji ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: bg,
              gradient: isMe ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              borderRadius: radius,
              border: !isMe && isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
              boxShadow: [
                BoxShadow(
                  color: (isMe ? const Color(0xFF10B981) : Colors.black).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (largeEmoji)
                  Text(
                    text,
                    style: const TextStyle(fontSize: 40, height: 1.2),
                  )
                else
                  Text(
                    text,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38),
                    fontSize: 10,
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
