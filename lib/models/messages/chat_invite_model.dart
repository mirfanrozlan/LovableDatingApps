import '../user_model.dart';

class ChatInviteModel {
  final String friendStatus;
  final UserModel user;

  ChatInviteModel({
    required this.friendStatus,
    required this.user,
  });

  factory ChatInviteModel.fromJson(Map<String, dynamic> json) {
    return ChatInviteModel(
      friendStatus: json['friend_status'] ?? '',
      user: UserModel.fromJson(json),
    );
  }
}
