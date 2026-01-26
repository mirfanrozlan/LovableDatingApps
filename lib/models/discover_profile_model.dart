class DiscoverProfileModel {
  final int id;
  final String name;
  final String gender;
  final int age;
  final String description;
  final String education;
  final String subscription;
  final String status;
  final String media;
  final List<String> interests;
  final String state;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final double distance;

  DiscoverProfileModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.description,
    required this.education,
    required this.subscription,
    required this.status,
    required this.media,
    required this.interests,
    required this.state,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.distance = 0.0,
  });

  factory DiscoverProfileModel.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileModel(
      id: json['user_id'] ?? 0,
      name: json['user_name'] ?? '',
      gender: json['user_gender'] ?? '',
      age: json['user_age'] ?? 0,
      description: json['user_desc'] ?? '',
      education: json['user_education'] ?? '',
      subscription: json['user_subs'] ?? '',
      status: json['user_status'] ?? '',
      media: (json['user_media'] ?? '').toString().trim(),
      interests:
          (json['user_interest'] ?? '')
              .toString()
              .split(',')
              .where((e) => e.isNotEmpty)
              .toList(),
      state: json['user_state'] ?? '',
      city: json['user_city'] ?? '',
      country: json['user_country'] ?? '',
      latitude:
          double.tryParse(json['user_latitude']?.toString() ?? '0') ?? 0.0,
      longitude:
          double.tryParse(json['user_longitude']?.toString() ?? '0') ?? 0.0,
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
    );
  }
}
