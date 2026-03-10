import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> showPriceAlert({
    required String stationName,
    required double price,
    required String fuelType,
    String? address,
    double? distanceKm,
    DateTime? lastUpdated,
    bool playSound = true,
  }) async {
    final fuelLabel = fuelType.toUpperCase();
    final priceStr = price.toStringAsFixed(3);

    // Build rich body
    final distance = distanceKm != null && distanceKm > 0
        ? ' · ${distanceKm.toStringAsFixed(1)} km'
        : '';
    final updatedStr = _timeAgo(lastUpdated);
    final body =
        '$fuelLabel: $priceStr €/L$distance${updatedStr.isNotEmpty ? ' · $updatedStr' : ''}';

    final androidDetails = AndroidNotificationDetails(
      'price_alarm_final_v1',
      'Kraftstoff Preisalarm',
      channelDescription: 'Sofortige Warnung bei günstigen Kraftstoffpreisen',
      importance: Importance.max,
      priority: Priority.max,
      color: const Color(0xFF00C853),
      playSound: playSound,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
      styleInformation: address != null
          ? BigTextStyleInformation(
              '$body\n📍 $address',
              htmlFormatBigText: false,
              contentTitle: '⛽ Preisalarm: $stationName',
              htmlFormatContentTitle: false,
            )
          : BigTextStyleInformation(body),
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 42,
      title: '⛽ Preisalarm — $stationName',
      body: body,
      notificationDetails: details,
      payload: 'station_detail',
    );
  }

  /// Human-readable relative time ("aktualisiert vor 3 Min.").
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'gerade aktualisiert';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tag(en)';
  }
}
