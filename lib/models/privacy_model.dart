class PrivacyModel {
  final int privacyId;
  final int userId;
  final bool showProfile;
  final bool showIncognito;
  final bool showAge;
  final bool showDistance;
  final bool showPrecise;
  final bool showStatus;
  final bool showPrevious;

  PrivacyModel({
    required this.privacyId,
    required this.userId,
    required this.showProfile,
    required this.showIncognito,
    required this.showAge,
    required this.showDistance,
    required this.showPrecise,
    required this.showStatus,
    required this.showPrevious,
  });

  factory PrivacyModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val == '1';
      return false;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return PrivacyModel(
      privacyId: parseInt(json['privacy_id']),
      userId: parseInt(json['user_id']),
      showProfile: parseBool(json['show_profile']),
      showIncognito: parseBool(json['show_incognito']),
      showAge: parseBool(json['show_age']),
      showDistance: parseBool(json['show_distance']),
      showPrecise: parseBool(json['show_precise']),
      showStatus: parseBool(json['show_status']),
      showPrevious: parseBool(json['show_previous']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy_id': privacyId,
      'user_id': userId,
      'show_profile': showProfile ? 1 : 0,
      'show_incognito': showIncognito ? 1 : 0,
      'show_age': showAge ? 1 : 0,
      'show_distance': showDistance ? 1 : 0,
      'show_precise': showPrecise ? 1 : 0,
      'show_status': showStatus ? 1 : 0,
      'show_previous': showPrevious ? 1 : 0,
    };
  }

  PrivacyModel copyWith({
    int? privacyId,
    int? userId,
    bool? showProfile,
    bool? showIncognito,
    bool? showAge,
    bool? showDistance,
    bool? showPrecise,
    bool? showStatus,
    bool? showPrevious,
  }) {
    return PrivacyModel(
      privacyId: privacyId ?? this.privacyId,
      userId: userId ?? this.userId,
      showProfile: showProfile ?? this.showProfile,
      showIncognito: showIncognito ?? this.showIncognito,
      showAge: showAge ?? this.showAge,
      showDistance: showDistance ?? this.showDistance,
      showPrecise: showPrecise ?? this.showPrecise,
      showStatus: showStatus ?? this.showStatus,
      showPrevious: showPrevious ?? this.showPrevious,
    );
  }
}
