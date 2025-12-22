class UserModel {
  final int id;
  final String name;
  final String gender;
  final int age;
  final String description;
  final String education;
  final String subscription;
  final String status;
  final String media;
  final int locId;
  final String address;
  final String state;
  final String city;
  final String postcode;
  final String country;
  final int interestId;
  final String interests;

  UserModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.description,
    required this.education,
    required this.subscription,
    required this.status,
    required this.media,
    required this.locId,
    required this.address,
    required this.state,
    required this.city,
    required this.postcode,
    required this.country,
    required this.interestId,
    required this.interests,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String resolveUrl(String? url) {
      if (url == null || url.trim().isEmpty) return '';
      final cleanUrl = url.trim().replaceAll('`', '').replaceAll('\\', '/');
      if (cleanUrl.startsWith('http')) return cleanUrl;
      if (cleanUrl.startsWith('/'))
        return 'https://demo.mazri-minecraft.xyz$cleanUrl';
      return 'https://demo.mazri-minecraft.xyz/$cleanUrl';
    }

    return UserModel(
      id: json['user_id'] ?? 0,
      name: json['user_name'] ?? '',
      gender: json['user_gender'] ?? '',
      age: json['user_age'] ?? 0,
      description: json['user_desc'] ?? '',
      education: json['user_education'] ?? '',
      subscription: json['user_subs'] ?? '',
      status: json['user_status'] ?? '',
      media: resolveUrl(json['user_media']),
      locId: json['loc_id'] ?? 0,
      address: json['user_address'] ?? '',
      state: json['user_state'] ?? '',
      city: json['user_city'] ?? '',
      postcode: json['user_postcode'] ?? '',
      country: json['user_country'] ?? '',
      interestId: json['interest_id'] ?? 0,
      interests: json['user_interest'] ?? '',
    );
  }
}
