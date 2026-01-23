import '../user_model.dart';

class ChatInviteModel {
  final String friendStatus;
  final UserModel user;
  final int? inviteId;

  ChatInviteModel({
    required this.friendStatus,
    required this.user,
    this.inviteId,
  });

  factory ChatInviteModel.fromJson(Map<String, dynamic> json) {
    return ChatInviteModel(
      friendStatus: json['friend_status'] ?? '',
      user: UserModel.fromJson(json),
      inviteId: json['invite_id'] ?? json['id'] ?? json['user_id'],
    );
  }
}
