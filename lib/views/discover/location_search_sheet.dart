import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../controllers/discover_controller.dart';
import '../../routes.dart';

class LocationSearchSheet extends StatefulWidget {
  final bool navigateToDiscover;

  const LocationSearchSheet({super.key, this.navigateToDiscover = false});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final _controller = DiscoverController();
  final _mapController = MapController();
  final _searchController = TextEditingController();

  // Default to Kuala Lumpur
  LatLng _center = const LatLng(3.1390, 101.6869);
  String _address = 'Kuala Lumpur, Malaysia';
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (_controller.hasCustomLocation) {
      _center = LatLng(_controller.customLat!, _controller.customLng!);
      if (_controller.customLocationName != null) {
        _address = _controller.customLocationName!;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _center = camera.center;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        _getAddress(_center);
      });
    }
  }

  Future<LatLng?> _searchWithNominatim(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=1',
      );
      // Must include User-Agent for Nominatim
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LovableDatingApps/1.0',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        } else {
          print('Nominatim search returned no results for "$query"');
        }
      } else {
        print(
          'Nominatim search error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Nominatim search exception: $e');
    }
    return null;
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    print('Searching for: $query');
    setState(() => _loading = true);
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      // 1. Try exact search
      List<Location> locations = [];
      try {
        locations = await locationFromAddress(query);
      } catch (e) {
        print('Exact search failed: $e');
      }

      // 2. If not found and user didn't specify Malaysia, try appending it
      if (locations.isEmpty && !query.toLowerCase().contains('malaysia')) {
        try {
          print('Retrying with ", Malaysia"...');
          locations = await locationFromAddress('$query, Malaysia');
        } catch (e) {
          print('Malaysia append search failed: $e');
        }
      }

      // 3. Fallback to Nominatim if Geocoding plugin fails completely
      if (locations.isEmpty) {
        print('Geocoding plugin failed, trying Nominatim...');
        final nomResult = await _searchWithNominatim(query);
        if (nomResult != null) {
          // Create a dummy Location object to reuse existing logic or just use point directly
          // But since existing logic uses `locations` list, let's just handle it here.
          print(
            'Location found via Nominatim: ${nomResult.latitude}, ${nomResult.longitude}',
          );
          _mapController.move(nomResult, 13);
          _center = nomResult;
          await _getAddress(nomResult, fallbackLabel: query);
          return; // Exit early as we handled it
        } else {
          // Try Nominatim with Malaysia appended
          if (!query.toLowerCase().contains('malaysia')) {
            print('Nominatim retry with Malaysia...');
            final nomResult2 = await _searchWithNominatim('$query, Malaysia');
            if (nomResult2 != null) {
              print(
                'Location found via Nominatim (Malaysia): ${nomResult2.latitude}, ${nomResult2.longitude}',
              );
              _mapController.move(nomResult2, 13);
              _center = nomResult2;
              await _getAddress(nomResult2, fallbackLabel: query);
              return;
            }
          }
        }
      }

      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        print('Location found: ${loc.latitude}, ${loc.longitude}');
        final point = LatLng(loc.latitude, loc.longitude);

        _mapController.move(point, 13);
        _center = point;

        // Update address immediately to reflect the search result name (or reverse geocode again)
        // Pass the query as a fallback in case reverse geocoding fails
        await _getAddress(point, fallbackLabel: query);
      } else {
        print('No location found for "$query"');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not find "$query". Try adding the state or country.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Critical search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _reverseGeocodeWithNominatim(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&addressdetails=1',
      );
      // Must include User-Agent for Nominatim
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LovableDatingApps/1.0',
          'Accept-Language': 'en-US,en;q=0.9', // Request English results
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          // Construct readable address similar to placemark logic
          final List<String> parts = [];

          // Try suburb/district
          if (address['suburb'] != null)
            parts.add(address['suburb']);
          else if (address['district'] != null)
            parts.add(address['district']);
          else if (address['neighbourhood'] != null)
            parts.add(address['neighbourhood']);

          // Try city/town
          if (address['city'] != null)
            parts.add(address['city']);
          else if (address['town'] != null)
            parts.add(address['town']);
          else if (address['village'] != null)
            parts.add(address['village']);

          // Try state
          if (address['state'] != null) parts.add(address['state']);

          // Fallback to display_name if parts are too few
          if (parts.isEmpty && data['display_name'] != null) {
            // Take first 2-3 parts of display name for brevity
            final full = data['display_name'].toString().split(', ');
            if (full.length > 2) {
              return full.take(3).join(', ');
            }
            return data['display_name'];
          }

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      } else {
        print('Nominatim error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Nominatim reverse geocode error: $e');
    }
    return null;
  }

  Future<void> _getAddress(LatLng point, {String? fallbackLabel}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    String? readableAddress;

    try {
      // 1. Try standard Geocoding plugin
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        print('Reverse geocode result: $place'); // Debug print

        // Construct a readable address
        // Prioritize: subLocality > locality > subAdministrativeArea > administrativeArea > name > street
        final Set<String> parts = {}; // Use Set to avoid duplicates

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          parts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        // Fallback to name or street if city/state is missing
        if (parts.isEmpty) {
          if (place.name != null && place.name!.isNotEmpty) {
            parts.add(place.name!);
          }
          if (place.street != null && place.street!.isNotEmpty) {
            parts.add(place.street!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            parts.add(place.country!);
          }
        }

        if (parts.isNotEmpty) {
          readableAddress = parts.join(', ');
        }
      }
    } catch (e) {
      print('Standard reverse geocoding failed: $e');
    }

    // 2. Fallback to Nominatim if standard failed or returned nothing
    if (readableAddress == null || readableAddress.isEmpty) {
      print('Attempting Nominatim fallback for reverse geocoding...');
      readableAddress = await _reverseGeocodeWithNominatim(point);
    }

    // 3. Update UI
    if (mounted) {
      setState(() {
        if (readableAddress != null && readableAddress.isNotEmpty) {
          _address = readableAddress!;
        } else {
          _address =
              fallbackLabel ??
              'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        }
      });
      setState(() => _loading = false);
    }
  }

  void _confirmLocation() {
    _controller.setCustomLocation(
      _center.latitude,
      _center.longitude,
      _address,
    );
    Navigator.pop(context);
    if (widget.navigateToDiscover) {
      Navigator.pushReplacementNamed(context, AppRoutes.discover);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      Position position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);

      _mapController.move(point, 15);
      _center =
          point; // Update center manually as move might not trigger gesture
      await _getAddress(point);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.lovable.dating',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
            ],
          ),

          // Center Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 40,
              ), // Offset for pin point
              child: Icon(
                Icons.location_on_rounded,
                size: 50,
                color: const Color(0xFF10B981),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),

          // Header (Search Bar)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Search Input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search city, area...',
                            hintStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon:
                                  _loading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.search),
                              color: const Color(0xFF10B981),
                              onPressed:
                                  () => _performSearch(_searchController.text),
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: _performSearch,
                        ),
                        if (_loading)
                          const ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(30),
                            ),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: Color(0xFF10B981),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        color: const Color(0xFF10B981),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _loading
                                ? const Text('Loading address...')
                                : Text(
                                  _address,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _useCurrentLocation,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'My Location',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
