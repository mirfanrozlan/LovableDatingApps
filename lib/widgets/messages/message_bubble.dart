import 'package:flutter/material.dart';
import '../../themes/theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const MessageBubble({super.key, required this.text, required this.isMe});

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
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: EdgeInsets.only(left: isMe ? 60 : 0, right: isMe ? 0 : 60, top: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: radius, boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 6)]),
          child: Text(text, style: TextStyle(color: fg)),
        ),
      ],
    );
  }
}