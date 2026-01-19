import 'dart:convert';
import 'package:flutter/services.dart';

class MalaysiaPostcodeService {
  static MalaysiaPostcodeService? _instance;
  Map<String, dynamic>? _data;
  List<MalaysiaState> _states = [];

  MalaysiaPostcodeService._();

  static MalaysiaPostcodeService get instance {
    _instance ??= MalaysiaPostcodeService._();
    return _instance!;
  }

  Future<void> loadData() async {
    if (_data != null) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/malaysia_postcodes.json');
      _data = jsonDecode(jsonString);
      _parseData();
    } catch (e) {
      print('Error loading Malaysia postcodes: $e');
      _states = [];
    }
  }

  void _parseData() {
    if (_data == null) return;
    
    final statesData = _data!['states'] as List<dynamic>?;
    if (statesData == null) return;

    _states = statesData.map((state) {
      final citiesData = state['cities'] as List<dynamic>? ?? [];
      final cities = citiesData.map((city) {
        final postcodes = (city['postcodes'] as List<dynamic>?)
            ?.map((p) => p.toString())
            .toList() ?? [];
        return MalaysiaCity(
          name: city['name'] ?? '',
          postcodes: postcodes,
        );
      }).toList();
      
      return MalaysiaState(
        name: state['name'] ?? '',
        code: state['code'] ?? '',
        cities: cities,
      );
    }).toList();

    // Sort states alphabetically
    _states.sort((a, b) => a.name.compareTo(b.name));
  }

  List<String> getStateNames() {
    return _states.map((s) => s.name).toList();
  }

  List<String> getCitiesForState(String stateName) {
    final state = _states.firstWhere(
      (s) => s.name == stateName,
      orElse: () => MalaysiaState(name: '', code: '', cities: []),
    );
    final cityNames = state.cities.map((c) => c.name).toList();
    cityNames.sort();
    return cityNames;
  }

  List<String> getPostcodesForCity(String stateName, String cityName) {
    final state = _states.firstWhere(
      (s) => s.name == stateName,
      orElse: () => MalaysiaState(name: '', code: '', cities: []),
    );
    final city = state.cities.firstWhere(
      (c) => c.name == cityName,
      orElse: () => MalaysiaCity(name: '', postcodes: []),
    );
    final postcodes = List<String>.from(city.postcodes);
    postcodes.sort();
    return postcodes;
  }

  /// Find state and city by postcode
  PostcodeLookupResult? findByPostcode(String postcode) {
    for (final state in _states) {
      for (final city in state.cities) {
        if (city.postcodes.contains(postcode)) {
          return PostcodeLookupResult(
            state: state.name,
            city: city.name,
            postcode: postcode,
          );
        }
      }
    }
    return null;
  }
}

class MalaysiaState {
  final String name;
  final String code;
  final List<MalaysiaCity> cities;

  MalaysiaState({
    required this.name,
    required this.code,
    required this.cities,
  });
}

class MalaysiaCity {
  final String name;
  final List<String> postcodes;

  MalaysiaCity({
    required this.name,
    required this.postcodes,
  });
}

class PostcodeLookupResult {
  final String state;
  final String city;
  final String postcode;

  PostcodeLookupResult({
    required this.state,
    required this.city,
    required this.postcode,
  });
}
