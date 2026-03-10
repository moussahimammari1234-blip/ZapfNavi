import 'package:flutter/material.dart';

enum PriceTrend { up, down, stable }

class PriceRecommendation {
  final String message;
  final String subMessage;
  final IconData icon;
  final Color color;
  final PriceTrend trend;

  PriceRecommendation({
    required this.message,
    required this.subMessage,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

class PriceForecastService {
  static final PriceForecastService _instance =
      PriceForecastService._internal();
  factory PriceForecastService() => _instance;
  PriceForecastService._internal();

  PriceRecommendation getRecommendation() {
    final now = DateTime.now();
    final hour = now.hour;

    // German Fuel Price Patterns (Approximate based on market data)
    // 00:00 - 05:00 -> High (Night prices)
    // 05:00 - 09:00 -> Very High (Morning peak)
    // 09:00 - 12:00 -> Dropping
    // 12:00 - 13:00 -> Small peak
    // 13:00 - 17:00 -> Dropping
    // 17:00 - 18:00 -> Small peak
    // 18:00 - 22:00 -> LOW (Best time to refuel)
    // 22:00 - 00:00 -> Rising

    if (hour >= 18 && hour <= 21) {
      return PriceRecommendation(
        message: 'Jetzt tanken!',
        subMessage:
            'Die Preise sind aktuell auf dem Tagestiefststand. Günstiger wird es heute wahrscheinlich nicht mehr.',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF00C853),
        trend: PriceTrend.down,
      );
    } else if (hour >= 5 && hour <= 9) {
      return PriceRecommendation(
        message: 'Warten empfohlen',
        subMessage:
            'Morgendliche Preisspitze. Die Preise fallen erfahrungsgemäß ab ca. 10:00 Uhr deutlich.',
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFFFFAB00),
        trend: PriceTrend.up,
      );
    } else if (hour >= 22 || hour <= 4) {
      return PriceRecommendation(
        message: 'Eher teuer',
        subMessage:
            'Nachttarif aktiv. Wenn möglich, warte bis zum späten Nachmittag oder Abend.',
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFFFF5252),
        trend: PriceTrend.up,
      );
    } else if (hour >= 10 && hour <= 17) {
      return PriceRecommendation(
        message: 'Guter Zeitpunkt',
        subMessage:
            'Preise sind moderat. Wer ganz sicher gehen will, wartet bis nach 18:00 Uhr für das absolute Tief.',
        icon: Icons.info_rounded,
        color: const Color(0xFF2979FF),
        trend: PriceTrend.down,
      );
    } else {
      return PriceRecommendation(
        message: 'Preise stabil',
        subMessage:
            'Aktuell keine großen Sprünge erwartet. Preise verhalten sich dem Marktdurchschnitt entsprechend.',
        icon: Icons.trending_flat_rounded,
        color: const Color(0xFF90A4AE),
        trend: PriceTrend.stable,
      );
    }
  }
}
