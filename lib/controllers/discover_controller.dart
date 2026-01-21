import 'package:flutter/material.dart';
import '../models/discover_profile_model.dart';
import '../services/discover_service.dart';

class DiscoverController extends ChangeNotifier {
  static final DiscoverController _instance = DiscoverController._internal();
  factory DiscoverController() => _instance;
  DiscoverController._internal();

  final _service = DiscoverService();
  List<DiscoverProfileModel> _profiles = [];
  bool _loading = false;
  int _page = 1;
  int _limit = 5;
  int _swipeCount = 0;
  bool _hasMore = true;
  final Set<int> _seenIds = {};

  // Filters
  int? _distance;
  String? _gender;
  int? _minAge;
  int? _maxAge;


  List<DiscoverProfileModel> get profiles => _profiles;
  bool get loading => _loading;
  
  int? get distance => _distance;
  String? get gender => _gender;
  int? get minAge => _minAge;
  int? get maxAge => _maxAge;
  bool get isDiscoveryDarkMode => true; // Replaced during cleanup


  void updateFilters({
    int? distance,
    String? gender,
    int? minAge,
    int? maxAge,
  }) {
    _distance = distance;
    _gender = gender;
    _minAge = minAge;
    _maxAge = maxAge;
    
    // Reset pagination and reload
    _page = 1;
    _profiles = [];
    _seenIds.clear();
    _hasMore = true;
    _swipeCount = 0;
    notifyListeners();
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    print('Discover: loading page=$_page limit=$_limit filters=(dist:$_distance, gender:$_gender, age:$_minAge-$_maxAge)');
    final newProfiles = await _service.getRandomPeople(
      page: _page, 
      limit: _limit,
      distance: _distance,
      gender: _gender,
      minAge: _minAge,
      maxAge: _maxAge,
    );
    print('Discover: received=${newProfiles.length} profiles from API');
    if (newProfiles.isNotEmpty) {
      final deduped = <DiscoverProfileModel>[];
      for (final p in newProfiles) {
        if (_seenIds.add(p.id)) {
          deduped.add(p);
        }
      }
      if (deduped.isNotEmpty) {
        _profiles.addAll(deduped);
        _page++;
        _hasMore = true;
        print('Discover: added=${deduped.length} total=${_profiles.length} nextPage=$_page');
      } else {
        // All were duplicates: advance page and attempt again next time
        _page++;
        print('Discover: duplicates only, advancing to page=$_page');
      }
    } else {
      _hasMore = false;
      print('Discover: no more results, hasMore=$_hasMore');
    }

    _loading = false;
    notifyListeners();
  }

  void removeProfile(DiscoverProfileModel p) {
    _profiles.remove(p);
    notifyListeners();
    _swipeCount++;
    print('Discover: removed id=${p.id} swipeCount=$_swipeCount deck=${_profiles.length}');
    final shouldPrefetchOnSwipe = _swipeCount % 3 == 0;
    final isDeckLow = _profiles.length <= 2;
    if (shouldPrefetchOnSwipe && _hasMore) {
      print('Discover: prefetching on 3rd swipe (page=$_page)');
      loadProfiles();
    } else if (isDeckLow && !_hasMore) {
      // Wrap-around: restart pagination
      _page = 1;
      _hasMore = true;
      _seenIds.clear();
      print('Discover: deck low and no more pages, wrapping to page=$_page');
      loadProfiles();
    } else if (isDeckLow && !_loading) {
      // Keep deck healthy even when not hitting 3rd swipe
      print('Discover: deck low, prefetching to keep deck healthy (page=$_page)');
      loadProfiles();
    }
  }

  void like(DiscoverProfileModel p) {
    removeProfile(p);
  }

  void dislike(DiscoverProfileModel p) {
    removeProfile(p);
  }
}
