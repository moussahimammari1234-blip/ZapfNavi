import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationSuggestion {
  final String label;
  final String city;
  final double lat;
  final double lng;

  LocationSuggestion({
    required this.label,
    required this.city,
    required this.lat,
    required this.lng,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<List<LocationSuggestion>> getSuggestions(String query) async {
    if (query.trim().length < 3) return [];

    // Nominatim API: Search for cities/addresses in Germany
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=5'
      '&countrycodes=de',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'ZapfNavi/1.0',
        'Accept-Language': 'de',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) {
          final address = item['address'] as Map<String, dynamic>?;
          final city = address?['city'] ??
              address?['town'] ??
              address?['village'] ??
              address?['suburb'] ??
              '';

          return LocationSuggestion(
            label: item['display_name'] ?? '',
            city: city,
            lat: double.parse(item['lat']),
            lng: double.parse(item['lon']),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('📍 Error getting location suggestions: $e');
    }
    return [];
  }
}
