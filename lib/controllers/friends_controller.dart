class FriendSuggestion {
  final String name;
  final String location;
  final double distanceKm;
  final List<String> interests;
  final String initials;
  FriendSuggestion(
    this.name,
    this.location,
    this.distanceKm,
    this.interests,
    this.initials,
  );
}

class MessageRequest {
  final String from;
  final String text;
  final String initials;
  MessageRequest(this.from, this.text, this.initials);
}

class FriendsController {
  List<FriendSuggestion> youMayKnow() => [
    FriendSuggestion('Chelsea', 'Petaling Jaya, Selangor', 1.2, [
      'Art',
      'Coffee',
    ], 'CH'),
    FriendSuggestion('Mei', 'KLCC, Kuala Lumpur', 5.6, [
      'Yoga',
      'Travel',
    ], 'ME'),
  ];

  List<FriendSuggestion> nearby() => [
    FriendSuggestion('Emma', 'Bukit Bintang, KL', 3.2, [
      'Yoga',
      'Art',
      'Coffee',
    ], 'EM'),
    FriendSuggestion('Sophia', 'KLCC, Kuala Lumpur', 5.8, [
      'Food',
      'Wine',
      'Beach',
    ], 'SO'),
    FriendSuggestion('Olivia', 'Cheras, KL', 7.3, [
      'Dancing',
      'Tech',
      'Music',
    ], 'OL'),
  ];

  List<MessageRequest> requests() => [
    MessageRequest(
      'Emma',
      "Hi! I saw your profile and thought we might have a lot in common.",
      'EM',
    ),
    MessageRequest(
      'Sophia',
      "Loved your gallery photos! Want to grab coffee?",
      'SO',
    ),
    MessageRequest(
      'Olivia',
      "Hey there! I'm new around here. Where's a good cafe?",
      'OL',
    ),
  ];

  List<FriendSuggestion> matches() => [
    FriendSuggestion('Eric', 'KLCC, Kuala Lumpur', 4.1, [
      'Hiking',
      'Coffee',
    ], 'ER'),
    FriendSuggestion('Emma', 'Bukit Bintang, KL', 3.2, ['Yoga', 'Art'], 'EM'),
  ];
}
