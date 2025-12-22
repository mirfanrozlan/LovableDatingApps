class ChatSummaryModel {
  final String id;
  final String name;
  final String initials;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final int unread;

  ChatSummaryModel({
    required this.id,
    required this.name,
    required this.initials,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
  });
}
