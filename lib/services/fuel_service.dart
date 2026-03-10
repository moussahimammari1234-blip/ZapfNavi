import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fuel_station.dart';
import 'config_service.dart';

class FuelService {
  static final FuelService _instance = FuelService._internal();
  factory FuelService() => _instance;
  FuelService._internal();

  // API key is loaded from Supabase — NOT hardcoded here
  static const String _baseUrl = 'https://www.tankerkoenig.de';
  final Random _random = Random();

  /// Fetch the API key securely from Supabase (cached after first call)
  Future<String?> _getApiKey() => ConfigService().getTankerkoenigApiKey();

  // ─── Bulk Price Update ────────────────────────────────────────────────────
  Future<Map<String, Map<String, double?>>> getPricesByIds(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    final Map<String, Map<String, double?>> results = {};

    // Fetch API key from Supabase
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      debugPrint('🛢️ getPricesByIds: No API key available.');
      return results;
    }

    try {
      // Tankerkönig limits IDs per request. Let's chunk in groups of 10.
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final idsString = chunk.join(',');
        final url = Uri.parse(
            '$_baseUrl/json/prices.php?ids=$idsString&apikey=$apiKey');

        final response =
            await http.get(url).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          String rawBody = response.body.trim();
          if (rawBody.startsWith('(') && rawBody.endsWith(')')) {
            rawBody = rawBody.substring(1, rawBody.length - 1).trim();
          }

          final data = json.decode(rawBody);
          if (data is Map<String, dynamic> &&
              data['ok'] == true &&
              data['prices'] != null) {
            final Map<String, dynamic> pricesMap = data['prices'];
            pricesMap.forEach((stationId, prices) {
              results[stationId] = {
                'e5': (prices['e5'] is num)
                    ? (prices['e5'] as num).toDouble()
                    : null,
                'e10': (prices['e10'] is num)
                    ? (prices['e10'] as num).toDouble()
                    : null,
                'diesel': (prices['diesel'] is num)
                    ? (prices['diesel'] as num).toDouble()
                    : null,
              };
            });
          }
        }
        // Small delay between chunks to be nice to the API
        if (i + 10 < ids.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      debugPrint('🛢️ Error fetching detailed prices: $e');
    }
    return results;
  }

  // ─── Nearby Stations ────────────────────────────────────────────────────
  Future<List<FuelStation>> getNearbyStations({
    double lat = 52.5200,
    double lng = 13.4050,
    double radius = 5.0,
    String fuelType = 'e5',
    String? city,
  }) async {
    // Fetch API key from Supabase
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      debugPrint('🛢️ getNearbyStations: No API key — using mock data.');
      return _mockStations(lat, lng, city: city);
    }

    // List of stable endpoints - STRICT HTTPS
    final endpoints = [
      'https://creativecommons.tankerkoenig.de',
      'https://www.tankerkoenig.de',
      'https://tankerkoenig.de',
    ];

    String lastError = 'Initialisierung...';

    for (String baseUrl in endpoints) {
      try {
        // ✅ Use type=all to get ALL fuel prices (E5, E10, Diesel) in ONE call
        final url = Uri.parse(
          '$baseUrl/json/list.php'
          '?lat=$lat&lng=$lng&rad=$radius&type=all'
          '&sort=dist&apikey=$apiKey',
        );

        debugPrint('🛢️ Versuche: $baseUrl (type=all)');

        final response = await http.get(url, headers: {
          'Accept': 'application/json',
          'User-Agent': 'ZapfNavi/1.0',
        }).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          // --- CLEANING LOGIC ---
          String rawBody = response.body.trim();

          // Remove potential parentheses wrapping (JSONP)
          if (rawBody.startsWith('(') && rawBody.endsWith(')')) {
            rawBody = rawBody.substring(1, rawBody.length - 1).trim();
          }

          final dynamic decoded = json.decode(rawBody);
          List<dynamic> stationsJson = [];

          if (decoded is Map<String, dynamic>) {
            if (decoded['ok'] == true) {
              stationsJson = decoded['stations'] as List? ?? [];
            } else {
              lastError = 'API: ${decoded['message'] ?? 'Status False'}';
              continue;
            }
          } else if (decoded is List) {
            // Direct list of stations
            stationsJson = decoded;
          }

          if (stationsJson.isNotEmpty) {
            // Parse stations — all 3 prices are now in the response
            final stations = stationsJson
                .map((s) =>
                    FuelStation.fromTankerkoenig(s as Map<String, dynamic>,
                        lat: lat,
                        lng: lng,
                        // No requestedFuelType: parse all fields directly
                        requestedFuelType: null))
                .toList();

            // Sort by the user's selected fuel type price (cheapest first)
            stations.sort((a, b) {
              final priceA = a.getPriceForType(fuelType) ?? double.infinity;
              final priceB = b.getPriceForType(fuelType) ?? double.infinity;
              return priceA.compareTo(priceB);
            });

            return stations;
          } else {
            lastError = '0 Tankstellen gefunden (Radius: ${radius}km).';
          }
        } else {
          lastError = 'HTTP ${response.statusCode}';
        }
      } catch (e) {
        lastError = 'Fehler: $e';
      }
    }

    if (lastError.contains('0 Tankstellen')) {
      return _mockStations(lat, lng, city: city);
    }

    throw Exception('Verbindung fehlgeschlagen.\nDetail: $lastError');
  }

  // ─── Station Detail ───────────────────────────────────────────────────────
  Future<FuelStation?> getStationDetail(String id) async {
    if (id.startsWith('mock_')) {
      // Don't call API for mock stations
      final mocks = _mockStations(52.52, 13.40);
      try {
        return mocks.firstWhere((s) => s.id == id);
      } catch (_) {
        return mocks.first;
      }
    }

    try {
      // Fetch API key from Supabase
      final apiKey = await _getApiKey();
      if (apiKey == null) return null;

      final url = Uri.parse(
        '$_baseUrl/json/detail.php?id=$id&apikey=$apiKey',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['ok'] == true && data['station'] != null) {
          return FuelStation.fromTankerkoenig(
            data['station'] as Map<String, dynamic>,
            lat: 0,
            lng: 0,
          );
        }
      }
    } catch (e) {
      debugPrint('🛢️ Detail Error: $e');
    }
    return null;
  }

  // ─── Price History (simulated, Tankerkönig doesn't provide this) ──────────
  Future<List<PriceHistory>> getPriceHistory(
    String stationId,
    String fuelType,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final base = fuelType == 'diesel' ? 1.639 : 1.799;
    return List.generate(24, (i) {
      final variation = (_random.nextDouble() - 0.5) * 0.12;
      return PriceHistory(
        timestamp: now.subtract(Duration(hours: i * 2)),
        price: double.parse((base + variation).toStringAsFixed(3)),
        fuelType: fuelType,
      );
    }).reversed.toList();
  }

  // ─── Mock Data (Fallback) ─────────────────────────────────────────────────
  List<FuelStation> _mockStations(double lat, double lng, {String? city}) {
    debugPrint('🛢️ ⚠️ Using MOCK data (API unavailable)');
    final cityName = city ?? 'In der Nähe';

    final brands = [
      {'name': 'Aral Tankstelle', 'brand': 'Aral'},
      {'name': 'Shell Station', 'brand': 'Shell'},
      {'name': 'JET Tankstelle', 'brand': 'JET'},
      {'name': 'TotalEnergies', 'brand': 'Total'},
      {'name': 'ESSO Station', 'brand': 'ESSO'},
      {'name': 'BP Station', 'brand': 'BP'},
      {'name': 'Westfalen Tank', 'brand': 'Westfalen'},
      {'name': 'HEM Tankstelle', 'brand': 'HEM'},
      {'name': 'STAR Tankstelle', 'brand': 'STAR'},
      {'name': 'Agip ENI', 'brand': 'Agip'},
      {'name': 'Q1 Tankstelle', 'brand': 'Q1'},
      {'name': 'Avia Tankstelle', 'brand': 'Avia'},
      {'name': 'Raiffeisen Tank', 'brand': 'Raiffeisen'},
      {'name': 'Supol Station', 'brand': 'Supol'},
      {'name': 'Freie Tankstelle', 'brand': 'Freie'},
    ];

    return List.generate(5, (i) {
      final brand = brands[i % brands.length];
      final e5 = 1.799 + (i * 0.009) - (_random.nextDouble() * 0.06);
      final diesel = 1.639 + (i * 0.008) - (_random.nextDouble() * 0.05);
      final e10 = e5 - 0.020;
      return FuelStation(
        id: 'mock_$i',
        name: '${brand['name']!} (Demo)',
        brand: brand['brand']!,
        address: 'Musterstraße ${10 + i * 4}',
        city: cityName,
        latitude: lat + (0.006 * (i % 5)) - 0.012,
        longitude: lng + (0.006 * (i ~/ 5)) - 0.009,
        distanceKm: 0.3 + i * 0.38,
        e5: double.parse(e5.toStringAsFixed(3)),
        e10: double.parse(e10.toStringAsFixed(3)),
        diesel: double.parse(diesel.toStringAsFixed(3)),
        isOpen: i % 6 != 3,
        openingHours: i % 6 == 3 ? 'Geschlossen' : '24h geöffnet',
        hasTruck: i % 3 == 0,
        hasCar: true,
        lastUpdated: DateTime.now().subtract(
          Duration(minutes: _random.nextInt(45)),
        ),
      );
    });
  }
}
