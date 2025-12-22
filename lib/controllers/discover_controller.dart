import 'package:flutter/material.dart';
import '../models/discover_profile_model.dart';
import '../services/discover_service.dart';

class DiscoverController extends ChangeNotifier {
  final _service = DiscoverService();
  List<DiscoverProfileModel> _profiles = [];
  bool _loading = false;
  int _page = 1;

  List<DiscoverProfileModel> get profiles => _profiles;
  bool get loading => _loading;

  Future<void> loadProfiles() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    final newProfiles = await _service.getRandomPeople(page: _page);
    if (newProfiles.isNotEmpty) {
      _profiles.addAll(newProfiles);
      _page++;
    }

    _loading = false;
    notifyListeners();
  }

  void removeProfile(DiscoverProfileModel p) {
    _profiles.remove(p);
    notifyListeners();
    if (_profiles.length < 3) {
      loadProfiles();
    }
  }

  void like(DiscoverProfileModel p) {
    // Implement like API call here
    removeProfile(p);
  }

  void dislike(DiscoverProfileModel p) {
    // Implement dislike API call here
    removeProfile(p);
  }
}
