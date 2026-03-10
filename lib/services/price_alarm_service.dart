import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'fuel_service.dart';
import 'notification_service.dart';
import '../models/fuel_station.dart';
import '../models/alarm_config.dart';

/// PriceAlarmService — extended P2 version.
///
/// Checks prices and notifies user respecting:
/// • Scope: region (last GPS / search center) or favorites-only
/// • onlyOpen: skip closed stations when true
/// • cooldown: minimum minutes between alerts (per alarm config)
/// • quietHours: suppress notifications between quietStart–quietEnd
/// • No ACCESS_BACKGROUND_LOCATION required — uses last known position
class PriceAlarmService {
  static final PriceAlarmService _instance = PriceAlarmService._internal();
  factory PriceAlarmService() => _instance;
  PriceAlarmService._internal();

  /// Main entry point — called from WorkManager or UI.
  Future<void> checkAndNotify() async {
    await checkPriceAlarm();
    await checkDailyLowPriceTrigger();
  }

  Future<void> checkPriceAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── 1. Load full alarm config ──────────────────────────────────────
      final scopeStr = prefs.getString(AlarmConfig.kScope) ?? 'region';
      final alarm = AlarmConfig(
        enabled: prefs.getBool(AlarmConfig.kEnabled) ?? false,
        fuelType: prefs.getString(AlarmConfig.kFuelType) ?? 'e5',
        thresholdPrice: prefs.getDouble(AlarmConfig.kThreshold) ?? 1.70,
        scope:
            scopeStr == 'favorites' ? AlarmScope.favorites : AlarmScope.region,
        onlyOpen: prefs.getBool(AlarmConfig.kOnlyOpen) ?? true,
        cooldownMinutes: prefs.getInt(AlarmConfig.kCooldown) ?? 30,
        quietHoursEnabled: prefs.getBool(AlarmConfig.kQuietEnabled) ?? false,
        quietStartHour: prefs.getInt(AlarmConfig.kQuietStartHour) ?? 22,
        quietStartMinute: prefs.getInt(AlarmConfig.kQuietStartMin) ?? 0,
        quietEndHour: prefs.getInt(AlarmConfig.kQuietEndHour) ?? 7,
        quietEndMinute: prefs.getInt(AlarmConfig.kQuietEndMin) ?? 0,
        soundEnabled: prefs.getBool(AlarmConfig.kSound) ?? true,
      );

      if (!alarm.enabled) {
        debugPrint('🔔 PriceAlarm: Disabled — skipping.');
        return;
      }

      // ── 2. Quiet hours check ───────────────────────────────────────────
      if (alarm.quietHoursEnabled && _isInQuietHours(alarm)) {
        debugPrint('🔔 PriceAlarm: In quiet hours — skipping.');
        return;
      }

      // ── 3. Cooldown check ─────────────────────────────────────────────
      final lastNotifiedMs = prefs.getInt(AlarmConfig.kLastNotified) ?? 0;
      final lastNotified = DateTime.fromMillisecondsSinceEpoch(lastNotifiedMs);
      final cooldown = Duration(minutes: alarm.cooldownMinutes);
      if (DateTime.now().difference(lastNotified) < cooldown) {
        debugPrint(
            '🔔 PriceAlarm: Cooldown active (${alarm.cooldownMinutes} min) — skipping.');
        return;
      }

      // ── 4. Get stations (scope-dependent) ─────────────────────────────
      List<FuelStation> candidates;

      if (alarm.scope == AlarmScope.favorites) {
        candidates = await _getFavoriteStations(prefs, alarm.fuelType);
      } else {
        candidates = await _getRegionStations(prefs, alarm);
      }

      if (candidates.isEmpty) {
        debugPrint(
            '🔔 PriceAlarm: No stations found for scope ${alarm.scope}.');
        return;
      }

      // ── 5. Apply onlyOpen filter ───────────────────────────────────────
      if (alarm.onlyOpen) {
        candidates = candidates.where((s) => s.isOpen).toList();
        if (candidates.isEmpty) {
          debugPrint(
              '🔔 PriceAlarm: No OPEN stations — skipping (onlyOpen=true).');
          return;
        }
      }

      // ── 6. Find the cheapest station below the threshold ──────────────
      FuelStation? bestMatch;
      double lowestPrice = 99.0;

      for (final station in candidates) {
        final price = station.getPriceForType(alarm.fuelType);
        if (price != null &&
            price > 0.1 &&
            price <= (alarm.thresholdPrice + 0.0005)) {
          if (price < lowestPrice) {
            lowestPrice = price;
            bestMatch = station;
          }
        }
      }

      // ── 7. Notify if match found ───────────────────────────────────────
      if (bestMatch != null) {
        debugPrint('🔔 PriceAlarm: MATCH! ${bestMatch.name} @ $lowestPrice');

        await NotificationService().showPriceAlert(
          stationName: bestMatch.name,
          price: lowestPrice,
          fuelType: alarm.fuelType,
          address: bestMatch.address,
          distanceKm: bestMatch.distanceKm,
          lastUpdated: bestMatch.lastUpdated,
        );

        // Record notification time for cooldown
        await prefs.setInt(
          AlarmConfig.kLastNotified,
          DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        debugPrint(
            '🔔 PriceAlarm: No prices matching threshold ${alarm.thresholdPrice}.');
      }
    } catch (e) {
      debugPrint('🔔 PriceAlarm Error: $e');
    }
  }

  Future<void> checkDailyLowPriceTrigger() async {
    try {
      final now = DateTime.now();
      final targetHours = [6, 7, 8, 10, 12, 14, 16, 18, 20];
      if (!targetHours.contains(now.hour)) {
        debugPrint(
            '🔔 DailyNotif: Not a target hour (${now.hour}) — skipping.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastHour = prefs.getInt('last_daily_notif_hour');
      final lastDay = prefs.getInt('last_daily_notif_day');

      if (lastHour == now.hour && lastDay == now.day) {
        debugPrint('🔔 DailyNotif: Already notified in this hour — skipping.');
        return;
      }

      if (!(prefs.getBool('notifications_enabled') ?? true)) return;

      // Fetch cheapest nearby
      final fuelType = prefs.getString(AlarmConfig.kFuelType) ?? 'diesel';
      final candidates = await _getRegionStations(prefs,
          AlarmConfig(enabled: true, fuelType: fuelType, thresholdPrice: 9.9));

      if (candidates.isEmpty) return;

      // Find absolute cheapest
      FuelStation? cheapest;
      double minPrice = 9.9;
      for (var s in candidates) {
        final p = s.getPriceForType(fuelType);
        if (p != null && p > 0.1 && p < minPrice) {
          minPrice = p;
          cheapest = s;
        }
      }

      if (cheapest != null) {
        await NotificationService().showPriceAlert(
          stationName: 'Tages-Deal: ${cheapest.name}',
          price: minPrice,
          fuelType: fuelType,
          address: cheapest.address,
          distanceKm: cheapest.distanceKm,
          lastUpdated: cheapest.lastUpdated,
        );

        await prefs.setInt('last_daily_notif_hour', now.hour);
        await prefs.setInt('last_daily_notif_day', now.day);
      }
    } catch (e) {
      debugPrint('🔔 DailyNotif Error: $e');
    }
  }

  /// Returns favorite stations with current prices.
  Future<List<FuelStation>> _getFavoriteStations(
      SharedPreferences prefs, String fuelType) async {
    try {
      // Favorite IDs are a comma-separated string (or use Supabase if logged in)
      final favIds = prefs.getStringList('local_favorite_ids') ?? [];
      if (favIds.isEmpty) return [];

      final prices = await FuelService().getPricesByIds(favIds);
      final stations = <FuelStation>[];

      for (final id in favIds) {
        if (prices.containsKey(id)) {
          final p = prices[id]!;
          stations.add(FuelStation(
            id: id,
            name: prefs.getString('fav_name_$id') ?? id,
            brand: prefs.getString('fav_brand_$id') ?? '',
            address: prefs.getString('fav_address_$id') ?? '',
            city: '',
            latitude: prefs.getDouble('fav_lat_$id') ?? 0,
            longitude: prefs.getDouble('fav_lng_$id') ?? 0,
            distanceKm: 0,
            isOpen: prefs.getBool('fav_open_$id') ?? true,
            lastUpdated: DateTime.now(),
            e5: p['e5'],
            e10: p['e10'],
            diesel: p['diesel'],
          ));
        }
      }
      return stations;
    } catch (e) {
      debugPrint('🔔 PriceAlarm: getFavorites error: $e');
      return [];
    }
  }

  /// Returns stations in the last used search region.
  /// Uses last-known GPS position and saved search radius.
  /// Does NOT require background GPS permission.
  Future<List<FuelStation>> _getRegionStations(
      SharedPreferences prefs, AlarmConfig alarm) async {
    // Try last known position first (no permission escalation)
    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // If no last-known, try a quick foreground poll (5s timeout, low accuracy)
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('🔔 PriceAlarm: Cannot get position — $e');
        return [];
      }
    }

    final radius = prefs.getDouble('searchRadius') ?? 10.0;
    return FuelService().getNearbyStations(
      lat: position.latitude,
      lng: position.longitude,
      radius: radius,
      fuelType: alarm.fuelType,
    );
  }

  /// Returns true if NOW is within the quiet-hours window.
  bool _isInQuietHours(AlarmConfig alarm) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = alarm.quietStartHour * 60 + alarm.quietStartMinute;
    final endMinutes = alarm.quietEndHour * 60 + alarm.quietEndMinute;

    if (startMinutes <= endMinutes) {
      // Same-day window, e.g. 08:00–20:00
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight window, e.g. 22:00–07:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }
}
