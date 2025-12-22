import 'package:flutter/material.dart';
import '../models/privacy_model.dart';
import '../services/privacy_service.dart';

class PrivacyController extends ChangeNotifier {
  final PrivacyService _service = PrivacyService();
  PrivacyModel? _privacy;
  bool _isLoading = false;
  String? _error;

  PrivacyModel? get privacy => _privacy;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PrivacyController() {
    loadPrivacy();
  }

  Future<void> loadPrivacy() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _privacy = await _service.getPrivacy();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrivacy(PrivacyModel newPrivacy) async {
    final oldPrivacy = _privacy;
    // Optimistic update
    _privacy = newPrivacy;
    notifyListeners();

    try {
      final result = await _service.setPrivacy(newPrivacy);
      if (result != null) {
        _privacy = result;
      } else {
        // Revert if API returns null (failure)
        _privacy = oldPrivacy;
        _error = "Failed to update settings";
      }
    } catch (e) {
      _privacy = oldPrivacy;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void toggleShowProfile(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showProfile: value));
    }
  }

  void toggleShowIncognito(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showIncognito: value));
    }
  }

  void toggleShowAge(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showAge: value));
    }
  }

  void toggleShowDistance(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showDistance: value));
    }
  }
  
  void toggleShowPrecise(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showPrecise: value));
    }
  }

  void toggleShowStatus(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showStatus: value));
    }
  }

  void toggleShowPrevious(bool value) {
    if (_privacy != null) {
      updatePrivacy(_privacy!.copyWith(showPrevious: value));
    }
  }
}
