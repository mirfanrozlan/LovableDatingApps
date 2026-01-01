class MessageModel {
  final String id;
  final String chatId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool largeEmoji;
  MessageModel({
    required this.id,
    required this.chatId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.largeEmoji = false,
  });
}
