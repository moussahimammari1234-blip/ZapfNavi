class FuelStation {
  final String id;
  final String name;
  final String brand;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double? diesel;
  final double? e5;
  final double? e10;
  final bool isOpen;
  final String? openingHours;
  final bool hasCar;
  final bool hasTruck;
  final DateTime lastUpdated;

  const FuelStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.diesel,
    this.e5,
    this.e10,
    required this.isOpen,
    this.openingHours,
    this.hasCar = true,
    this.hasTruck = false,
    required this.lastUpdated,
  });

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      address: json['street'] ?? '',
      city: json['place'] ?? '',
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? 0.0).toDouble(),
      distanceKm: (json['dist'] ?? 0.0).toDouble(),
      diesel:
          json['diesel'] != null ? (json['diesel'] as num).toDouble() : null,
      e5: json['e5'] != null ? (json['e5'] as num).toDouble() : null,
      e10: json['e10'] != null ? (json['e10'] as num).toDouble() : null,
      isOpen: json['isOpen'] ?? false,
      openingHours: json['openingTimes']?.toString(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Parse real Tankerkönig API v4 response
  factory FuelStation.fromTankerkoenig(
    Map<String, dynamic> json, {
    required double lat,
    required double lng,
    String? requestedFuelType,
  }) {
    // Build address string
    final street = json['street'] ?? json['address'] ?? '';
    final houseNumber = json['houseNumber'] ?? json['house_number'] ?? '';
    final address = houseNumber.isNotEmpty ? '$street $houseNumber' : street;

    // Parse prices — API returns false if price unavailable
    double? parsePrice(dynamic val) {
      if (val == null ||
          val == false ||
          val == 'null' ||
          val == 'false' ||
          val == 0 ||
          val == 0.0) {
        return null;
      }
      if (val is num) return val.toDouble() > 0 ? val.toDouble() : null;
      if (val is String) {
        final d = double.tryParse(val.replaceAll(',', '.'));
        return (d != null && d > 0) ? d : null;
      }
      return null;
    }

    // Distance parsing
    double dist = 0.0;
    if (json['dist'] is num) {
      dist = (json['dist'] as num).toDouble();
    } else if (json['dist'] is String) {
      dist = double.tryParse(json['dist']) ?? 0.0;
    }

    // Coordinate parsing
    double stationLat = lat;
    double stationLng = lng;
    if (json['lat'] is num) {
      stationLat = (json['lat'] as num).toDouble();
    } else if (json['lat'] is String) {
      stationLat = double.tryParse(json['lat']) ?? lat;
    }

    if (json['lng'] is num) {
      stationLng = (json['lng'] as num).toDouble();
    } else if (json['lng'] is String) {
      stationLng = double.tryParse(json['lng']) ?? lng;
    }

    // Parse opening times
    String? openingHours;
    final openTimes = json['openingTimes'];
    if (openTimes is List && openTimes.isNotEmpty) {
      final first = openTimes.first as Map<String, dynamic>?;
      if (first != null) {
        openingHours = '${first['start'] ?? ''} - ${first['end'] ?? ''}';
      }
    } else if (openTimes is String) {
      openingHours = openTimes;
    }

    // Extra robust price mapping
    double? pE5 = parsePrice(json['e5']) ??
        parsePrice(json['E5']) ??
        parsePrice(json['list_e5']);
    double? pE10 = parsePrice(json['e10']) ??
        parsePrice(json['E10']) ??
        parsePrice(json['list_e10']);
    double? pDiesel = parsePrice(json['diesel']) ??
        parsePrice(json['Diesel']) ??
        parsePrice(json['list_diesel']);
    double? genericPrice =
        parsePrice(json['price']) ?? parsePrice(json['amount']);

    // Only use generic price for the specific type that was searched if it's not already set
    if (genericPrice != null) {
      final type = requestedFuelType?.toLowerCase() ?? 'e5';
      if (type == 'diesel') {
        pDiesel ??= genericPrice;
      } else if (type == 'e10') {
        pE10 ??= genericPrice;
      } else if (type == 'e5') {
        pE5 ??= genericPrice;
      } else {
        // Fallback for unknown: if we still have nothing, put it into e5
        if (pE5 == null && pE10 == null && pDiesel == null) {
          pE5 = genericPrice;
        }
      }
    }

    // Secondary fallback: if we only have one price (e.g. from list.php),
    // and requested type is null, put it in e5
    if (pE5 == null &&
        pE10 == null &&
        pDiesel == null &&
        genericPrice != null) {
      pE5 = genericPrice;
    }

    return FuelStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['stationName'] ?? 'Unbekannte Station',
      brand: json['brand'] ?? json['stationBrand'] ?? '',
      address: address.trim(),
      city: json['place'] ?? json['city'] ?? '',
      latitude: stationLat,
      longitude: stationLng,
      distanceKm: dist,
      e5: pE5,
      e10: pE10,
      diesel: pDiesel,
      isOpen: json['isOpen'] == true ||
          json['is_open'] == true ||
          json['isOpen'] == 1,
      openingHours: openingHours,
      hasCar: json['hasCar'] != false,
      hasTruck: json['hasTruck'] == true,
      lastUpdated: DateTime.now(),
    );
  }

  FuelStation copyWith({
    double? diesel,
    double? e5,
    double? e10,
  }) {
    return FuelStation(
      id: id,
      name: name,
      brand: brand,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      diesel: diesel ?? this.diesel,
      e5: e5 ?? this.e5,
      e10: e10 ?? this.e10,
      isOpen: isOpen,
      openingHours: openingHours,
      hasCar: hasCar,
      hasTruck: hasTruck,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'street': address,
      'place': city,
      'lat': latitude,
      'lng': longitude,
      'dist': distanceKm,
      'diesel': diesel,
      'e5': e5,
      'e10': e10,
      'isOpen': isOpen,
    };
  }

  double? getPriceForType(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'diesel':
        return diesel;
      case 'e5':
        return e5;
      case 'e10':
        return e10;
      default:
        return e5;
    }
  }

  String get getTimeAgo {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tg.';
  }
}

class PriceHistory {
  final DateTime timestamp;
  final double price;
  final String fuelType;

  const PriceHistory({
    required this.timestamp,
    required this.price,
    required this.fuelType,
  });
}
