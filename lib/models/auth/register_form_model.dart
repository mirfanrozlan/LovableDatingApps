class RegisterFormModel {
  final String username;
  final String email;
  final String password;
  final int age;
  final String gender;
  final String interests;
  final String bio;
  final String education;
  final String address;
  final String postcode;
  final String state;
  final String city;
  final String country;
  final String phone;
  final String otp;
  final int minAge;
  final int maxAge;
  final int distanceKm;
  final String attractedGender;
  final String photoName;
  final String photoPath;

  RegisterFormModel({
    required this.username,
    required this.email,
    required this.password,
    required this.age,
    required this.gender,
    this.interests = '',
    this.bio = '',
    this.education = '',
    this.address = '',
    this.postcode = '',
    this.state = '',
    this.city = '',
    this.country = '',
    this.phone = '',
    this.otp = '',
    this.minAge = 18,
    this.maxAge = 18,
    this.distanceKm = 0,
    this.attractedGender = '',
    this.photoName = '',
    this.photoPath = '',
  });
}