import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fuel_station.dart';
import '../models/alarm_config.dart';
import '../services/fuel_service.dart';
import '../services/auth_service.dart';
import '../services/price_alarm_service.dart';

class FuelProvider extends ChangeNotifier {
  final FuelService _fuelService = FuelService();

  List<FuelStation> _stations = [];
  List<FuelStation> _filteredStations = [];
  // Route stations stored SEPARATELY to avoid overwriting main list
  List<FuelStation> _routeStations = [];
  final List<FuelStation> _favorites = [];
  final Set<String> _favoriteIds = {}; // fast lookup
  bool _isLoading = false;
  bool _isLocating = false;
  bool _isGpsDisabled = false; // GPS service is off
  String? _error;
  String _selectedFuelType = 'e5';
  double _searchRadius = 10.0;
  bool _showOnlyOpen = false;
  String _sortBy = 'price'; // price, distance
  String _searchQuery = '';
  String _selectedBrand = 'Alle';
  bool _showAllPrices = true;

  double _currentLat = 0;
  double _currentLng = 0;
  String _currentCity = '';

  // Getters
  List<FuelStation> get stations => _filteredStations;
  List<FuelStation> get routeStations => _routeStations;
  List<FuelStation> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isLocating => _isLocating;
  bool get isGpsDisabled => _isGpsDisabled;
  String? get error => _error;
  String get selectedFuelType => _selectedFuelType;
  double get searchRadius => _searchRadius;
  bool get showOnlyOpen => _showOnlyOpen;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  String get currentCity => _currentCity;
  bool get showAllPrices => _showAllPrices;

  double get averageSelectedPrice {
    if (_filteredStations.isEmpty) return 0.0;
    double total = 0;
    int count = 0;
    for (var s in _filteredStations) {
      final p = s.getPriceForType(_selectedFuelType);
      if (p != null) {
        total += p;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  double get minSelectedPrice {
    if (_filteredStations.isEmpty) return 0.0;
    double min = double.infinity;
    for (var s in _filteredStations) {
      final p = s.getPriceForType(_selectedFuelType);
      if (p != null && p < min) {
        min = p;
      }
    }
    return min == double.infinity ? 0.0 : min;
  }

  FuelProvider() {
    _initAll();
  }

  Future<void> _initAll() async {
    // MUST load preferences first so we have the correct fuelType & radius
    // before we start fetching stations from the API.
    await _loadPreferences();
    await _loadLocalFavorites(); // Load local first for guests
    await _initLocationAndLoad();
    _syncFavoritesFromSupabase();
    // Re-sync favorites when auth state changes
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        _syncFavoritesFromSupabase();
      });
    } catch (_) {}
  }

  Future<void> _initLocationAndLoad() async {
    _isLocating = true;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check if GPS is enabled FIRST
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS is disabled — not loading any stations.');
        _isGpsDisabled = true;
        _stations = [];
        _filteredStations = [];
        _isLocating = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isGpsDisabled = false;
      // 2. Try to get real location
      await determinePosition();
      // 3. Load stations only after getting real position
      await loadStations();
    } catch (e) {
      debugPrint('Init location error: $e');
    } finally {
      _isLocating = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Can be called from UI after user enables GPS
  Future<void> retryAfterGps() async {
    await _initLocationAndLoad();
    _syncFavoritesFromSupabase();
  }

  Future<void> determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // Try for 3 seconds to get a fresh position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('Fresh position timeout, trying last known... $e');
        // Fallback: Get last known position if current is too slow (common on some Androids)
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        _currentLat = position.latitude;
        _currentLng = position.longitude;

        // Get city name with shorter timeout
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentLat,
            _currentLng,
          ).timeout(const Duration(seconds: 2));

          if (placemarks.isNotEmpty) {
            _currentCity = placemarks.first.locality ?? 'Unbekannter Ort';
          }
        } catch (_) {
          _currentCity = 'Standort ermittelt';
        }
        notifyListeners();
      } else {
        debugPrint('Could not determine position (null)');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedFuelType = prefs.getString('fuelType') ?? 'e5';
    _searchRadius = prefs.getDouble('searchRadius') ?? 10.0;
    _showOnlyOpen = prefs.getBool('showOnlyOpen') ?? false;
    _showAllPrices = prefs.getBool('showAllPrices') ?? true; // Default ON
    notifyListeners();
  }

  Future<void> loadStations({double? lat, double? lng}) async {
    // If we're already loading, we might want to wait, but for startup,
    // we MUST ensure at least one load completes successfully.

    _currentLat = lat ?? _currentLat;
    _currentLng = lng ?? _currentLng;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _fuelService.getNearbyStations(
        lat: _currentLat,
        lng: _currentLng,
        radius: _searchRadius,
        fuelType: _selectedFuelType,
        city: _currentCity,
      );

      _stations = results;
      _applyFilters();
      _isLoading = false;
      notifyListeners(); // Show stations immediately

      // Then fetch detailed prices in the background to avoid blocking
      if (results.isNotEmpty) {
        final ids = results
            .map((s) => s.id)
            .where((id) => !id.startsWith('mock_'))
            .toList();
        if (ids.isNotEmpty) {
          final detailedPrices = await _fuelService.getPricesByIds(ids);
          if (detailedPrices.isNotEmpty) {
            _stations = _stations.map((s) {
              final p = detailedPrices[s.id];
              if (p != null) {
                return s.copyWith(
                  e5: p['e5'] ?? s.e5,
                  e10: p['e10'] ?? s.e10,
                  diesel: p['diesel'] ?? s.diesel,
                );
              }
              return s;
            }).toList();
            _applyFilters();
            notifyListeners();
          }
        }
      }

      _applyFilters();
      _reconcileFavorites();

      // Trigger Price Alarm check (fire and forget)
      PriceAlarmService().checkAndNotify();
    } catch (e) {
      debugPrint('LoadStations error: $e');
      _error = 'FEHLER: $e';
      _stations = [];
      _filteredStations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStationsAlongRoute({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<FuelStation> allFound = [];

      final points =
          _getPointsAlongRoute(startLat, startLng, destLat, destLng, 10);

      // Parallel fetch
      final results =
          await Future.wait(points.map((p) => _fuelService.getNearbyStations(
                lat: p['lat']!,
                lng: p['lng']!,
                radius: 25.0,
                fuelType: _selectedFuelType,
              )));

      for (var res in results) {
        allFound.addAll(res);
      }

      // De-duplicate by ID
      final Map<String, FuelStation> unique = {};
      for (var s in allFound) {
        unique[s.id] = s;
      }

      // ─── Store in _routeStations (NOT _stations!) ───────────────
      // This prevents the main fuel list from being overwritten when
      // the user navigates away and comes back.
      _routeStations = unique.values.toList();

      // Sort by distance from start point
      _routeStations.sort((a, b) {
        final distA = Geolocator.distanceBetween(
            startLat, startLng, a.latitude, a.longitude);
        final distB = Geolocator.distanceBetween(
            startLat, startLng, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
    } catch (e) {
      _error = 'Fehler beim Laden der Route-Tankstellen.';
      debugPrint('Route error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    var filtered = List<FuelStation>.from(_stations);

    if (_showOnlyOpen) {
      filtered = filtered.where((s) => s.isOpen).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(query) ||
                s.brand.toLowerCase().contains(query) ||
                s.address.toLowerCase().contains(query) ||
                s.city.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_selectedBrand != 'Alle') {
      filtered = filtered
          .where((s) =>
              s.brand.toLowerCase().contains(_selectedBrand.toLowerCase()))
          .toList();
    }

    if (_sortBy == 'price') {
      filtered.sort((a, b) {
        final priceA = a.getPriceForType(_selectedFuelType) ?? double.infinity;
        final priceB = b.getPriceForType(_selectedFuelType) ?? double.infinity;
        return priceA.compareTo(priceB);
      });
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else {
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    _filteredStations = filtered;
  }

  /// Set multiple filters at once and reload only once — use this from the filter screen
  Future<void> batchUpdate({
    double? radius,
    bool? showOnlyOpen,
    String? sortBy,
    String? fuelType,
    String? searchQuery,
    String? brand,
    double? targetLat,
    double? targetLng,
    String? targetCity,
    bool? showAllPrices,
  }) async {
    bool needsReload = false;
    bool locationFound = false;

    if (showAllPrices != null && showAllPrices != _showAllPrices) {
      _showAllPrices = showAllPrices;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showAllPrices', showAllPrices);
      if (_showAllPrices) needsReload = true;
    }

    // Use specific target location if provided (e.g. from autocomplete)
    if (targetLat != null && targetLng != null) {
      _currentLat = targetLat;
      _currentLng = targetLng;
      _currentCity = targetCity ?? searchQuery ?? 'Gewählter Ort';
      _searchQuery = ''; // Clear text filter as we are at new location
      locationFound = true;
      needsReload = true;
    }
    // Otherwise fallback to geocoding if searchQuery looks like a city
    else if (searchQuery != null && searchQuery.trim().length > 2) {
      try {
        List<Location> locations = await locationFromAddress(
          '${searchQuery.trim()}, Deutschland',
        );
        if (locations.isNotEmpty) {
          _currentLat = locations.first.latitude;
          _currentLng = locations.first.longitude;
          _currentCity = searchQuery.trim();
          _searchQuery = '';
          locationFound = true;
          needsReload = true;
          debugPrint('📍 Geocoded "$searchQuery" → $_currentLat, $_currentLng');
        }
      } catch (e) {
        debugPrint('📍 Not a location, treating as name filter: $e');
      }
    }

    // Only use as text-filter if geocoding failed
    if (!locationFound && searchQuery != null) {
      _searchQuery = searchQuery;
    }

    if (radius != null && radius != _searchRadius) {
      _searchRadius = radius;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('searchRadius', radius);
      needsReload = true;
    }
    if (showOnlyOpen != null) _showOnlyOpen = showOnlyOpen;
    if (sortBy != null) _sortBy = sortBy;
    if (fuelType != null && fuelType != _selectedFuelType) {
      _selectedFuelType = fuelType;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fuelType', fuelType);
      needsReload = true;
    }
    if (brand != null) _selectedBrand = brand;

    if (needsReload) {
      await loadStations();
    } else {
      _applyFilters();
      notifyListeners();
    }
  }

  void setFuelType(String type) async {
    if (_selectedFuelType == type) return; // no change
    _selectedFuelType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fuelType', type);
    // Tankerkönig returns different price fields per fuelType in list.php,
    // so we MUST reload from API when the type changes.
    await loadStations();
  }

  void setSearchRadius(double radius) async {
    _searchRadius = radius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('searchRadius', radius);
    notifyListeners();
    loadStations();
  }

  void setShowOnlyOpen(bool value) async {
    _showOnlyOpen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnlyOpen', value);
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setShowAllPrices(bool value) async {
    _showAllPrices = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAllPrices', value);
    notifyListeners();
  }

  void toggleFavorite(FuelStation station) async {
    if (_favoriteIds.contains(station.id)) {
      _favorites.removeWhere((f) => f.id == station.id);
      _favoriteIds.remove(station.id);
      AuthService().removeFavorite(station.id);
    } else {
      _favorites.add(station);
      _favoriteIds.add(station.id);
      AuthService().addFavorite(
        stationId: station.id,
        stationName: station.name,
        stationBrand: station.brand,
        stationAddress: '${station.address}, ${station.city}',
      );
    }
    await _saveLocalFavorites();
    notifyListeners();
  }

  Future<void> _loadLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList('local_favorites') ?? [];
    if (ids.isNotEmpty) {
      // If we already have ids from Supabase (sync started), only add what's missing
      for (var id in ids) {
        if (!_favoriteIds.contains(id)) {
          _favoriteIds.add(id);
          // Placeholder station until metadata is loaded or synced
          _favorites.add(FuelStation(
            id: id,
            name: 'Laden...',
            brand: 'Loading',
            address: '',
            city: '',
            latitude: 0,
            longitude: 0,
            distanceKm: 0,
            isOpen: true,
            lastUpdated: DateTime.now(),
          ));
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_favorites', _favoriteIds.toList());
  }

  bool isFavorite(String stationId) => _favoriteIds.contains(stationId);

  /// Load favorites from Supabase (if logged in) or keep local
  Future<void> _syncFavoritesFromSupabase() async {
    try {
      final remoteFavs = await AuthService().getFavorites();
      if (remoteFavs.isNotEmpty) {
        _favorites.clear();
        _favoriteIds.clear();
        for (final fav in remoteFavs) {
          final stationId = fav['station_id'] as String? ?? '';
          if (stationId.isEmpty) continue;
          _favoriteIds.add(stationId);
          // Build a lightweight FuelStation for favorites list
          _favorites.add(FuelStation(
            id: stationId,
            name: fav['station_name'] as String? ?? '',
            brand: fav['station_brand'] as String? ?? '',
            address: fav['station_address'] as String? ?? '',
            city: '',
            latitude: 0,
            longitude: 0,
            distanceKm: 0,
            isOpen: true,
            lastUpdated: DateTime.now(),
          ));
        }

        // Fetch prices for favorites to avoid "--" issue
        if (_favoriteIds.isNotEmpty) {
          try {
            final prices =
                await _fuelService.getPricesByIds(_favoriteIds.toList());
            for (int i = 0; i < _favorites.length; i++) {
              final pid = _favorites[i].id;
              if (prices.containsKey(pid)) {
                final p = prices[pid]!;
                _favorites[i] = _favorites[i].copyWith(
                  e5: p['e5'],
                  e10: p['e10'],
                  diesel: p['diesel'],
                );
              }
            }
          } catch (e) {
            debugPrint('Failed to fetch prices for sync favorites: $e');
          }
        }

        notifyListeners();
      }
    } catch (_) {
      // Not logged in or no internet — keep local favorites
    }
  }

  void _reconcileFavorites() {
    bool changed = false;
    for (int i = 0; i < _favorites.length; i++) {
      final favId = _favorites[i].id;
      // Find matches in loaded stations or route stations
      final match = _stations.cast<FuelStation?>().firstWhere(
            (s) => s?.id == favId,
            orElse: () => _routeStations.cast<FuelStation?>().firstWhere(
                  (rs) => rs?.id == favId,
                  orElse: () => null,
                ),
          );

      if (match != null) {
        // Update favorite with fresh details (prices, opening status, etc)
        _favorites[i] = match;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  FuelStation? getCheapestStation() {
    if (_filteredStations.isEmpty) return null;
    return _filteredStations.first;
  }

  List<Map<String, double>> _getPointsAlongRoute(
      double sLat, double sLng, double dLat, double dLng, int count) {
    final List<Map<String, double>> points = [];
    for (int i = 0; i < count; i++) {
      final double t = i / (count - 1);
      points.add({
        'lat': sLat + (dLat - sLat) * t,
        'lng': sLng + (dLng - sLng) * t,
      });
    }
    return points;
  }
}

class PremiumProvider extends ChangeNotifier {
  // Forced false for testing ads and per user request to remove premium
  bool get isPremium => false;

  void updateStatus() {
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    // Disabled
    notifyListeners();
  }
}

class AppProvider extends ChangeNotifier {
  bool _hasCompletedOnboarding = false;
  bool _notificationsEnabled = true;
  bool _avoidHighway = false;

  // All alarm settings encapsulated in AlarmConfig
  AlarmConfig _alarm = const AlarmConfig();

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get priceAlertsEnabled => _alarm.enabled;
  double get priceAlertThreshold => _alarm.thresholdPrice;
  String get priceAlertFuelType => _alarm.fuelType;
  bool get avoidHighway => _avoidHighway;

  // Full alarm config access
  AlarmConfig get alarmConfig => _alarm;

  AppProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool('onboarding_done') ?? false;
    _notificationsEnabled = prefs.getBool('notifs_enabled') ?? true;
    _avoidHighway = prefs.getBool('avoid_highway') ?? false;

    // Load AlarmConfig — migrates existing keys automatically
    final scopeStr = prefs.getString(AlarmConfig.kScope) ?? 'region';
    _alarm = AlarmConfig(
      enabled: prefs.getBool(AlarmConfig.kEnabled) ?? false,
      fuelType: prefs.getString(AlarmConfig.kFuelType) ?? 'e5',
      thresholdPrice: prefs.getDouble(AlarmConfig.kThreshold) ?? 1.70,
      scope: scopeStr == 'favorites' ? AlarmScope.favorites : AlarmScope.region,
      onlyOpen: prefs.getBool(AlarmConfig.kOnlyOpen) ?? true,
      cooldownMinutes: prefs.getInt(AlarmConfig.kCooldown) ?? 30,
      quietHoursEnabled: prefs.getBool(AlarmConfig.kQuietEnabled) ?? false,
      quietStartHour: prefs.getInt(AlarmConfig.kQuietStartHour) ?? 22,
      quietStartMinute: prefs.getInt(AlarmConfig.kQuietStartMin) ?? 0,
      quietEndHour: prefs.getInt(AlarmConfig.kQuietEndHour) ?? 7,
      quietEndMinute: prefs.getInt(AlarmConfig.kQuietEndMin) ?? 0,
      soundEnabled: prefs.getBool(AlarmConfig.kSound) ?? true,
    );
    notifyListeners();
  }

  Future<void> _saveAlarmConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AlarmConfig.kEnabled, _alarm.enabled);
    await prefs.setString(AlarmConfig.kFuelType, _alarm.fuelType);
    await prefs.setDouble(AlarmConfig.kThreshold, _alarm.thresholdPrice);
    await prefs.setString(AlarmConfig.kScope,
        _alarm.scope == AlarmScope.favorites ? 'favorites' : 'region');
    await prefs.setBool(AlarmConfig.kOnlyOpen, _alarm.onlyOpen);
    await prefs.setInt(AlarmConfig.kCooldown, _alarm.cooldownMinutes);
    await prefs.setBool(AlarmConfig.kQuietEnabled, _alarm.quietHoursEnabled);
    await prefs.setInt(AlarmConfig.kQuietStartHour, _alarm.quietStartHour);
    await prefs.setInt(AlarmConfig.kQuietStartMin, _alarm.quietStartMinute);
    await prefs.setInt(AlarmConfig.kQuietEndHour, _alarm.quietEndHour);
    await prefs.setInt(AlarmConfig.kQuietEndMin, _alarm.quietEndMinute);
    await prefs.setBool(AlarmConfig.kSound, _alarm.soundEnabled);
  }

  void _updateAlarm(AlarmConfig updated) {
    _alarm = updated;
    _saveAlarmConfig();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    notifyListeners();
  }

  void syncFromPrefs(bool hasCompletedOnboarding) {
    _hasCompletedOnboarding = hasCompletedOnboarding;
    notifyListeners();
  }

  void setNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifs_enabled', value);
    notifyListeners();
  }

  // ── Alarm setters (backwards-compatible names kept for existing callers) ──
  void setPriceAlerts(bool value) =>
      _updateAlarm(_alarm.copyWith(enabled: value));
  void setPriceAlertThreshold(double value) =>
      _updateAlarm(_alarm.copyWith(thresholdPrice: value));
  void setPriceAlertFuelType(String value) =>
      _updateAlarm(_alarm.copyWith(fuelType: value));

  // ── New P2 alarm setters ──────────────────────────────────────────────────
  void setAlarmScope(AlarmScope scope) =>
      _updateAlarm(_alarm.copyWith(scope: scope));
  void setAlarmOnlyOpen(bool value) =>
      _updateAlarm(_alarm.copyWith(onlyOpen: value));
  void setAlarmCooldown(int minutes) =>
      _updateAlarm(_alarm.copyWith(cooldownMinutes: minutes));
  void setAlarmQuietEnabled(bool value) =>
      _updateAlarm(_alarm.copyWith(quietHoursEnabled: value));
  void setAlarmQuietStart(int hour, int minute) => _updateAlarm(
      _alarm.copyWith(quietStartHour: hour, quietStartMinute: minute));
  void setAlarmQuietEnd(int hour, int minute) =>
      _updateAlarm(_alarm.copyWith(quietEndHour: hour, quietEndMinute: minute));
  void setAlarmSound(bool value) =>
      _updateAlarm(_alarm.copyWith(soundEnabled: value));

  void setAvoidHighway(bool value) async {
    _avoidHighway = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('avoid_highway', value);
    notifyListeners();
  }
}
