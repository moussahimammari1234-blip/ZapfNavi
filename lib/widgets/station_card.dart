import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';
import '../models/fuel_station.dart';

import 'price_display.dart';

// ─── Station Card ──────────────────────────────────────────────────────────────
class StationCard extends StatelessWidget {
  final FuelStation station;
  final String fuelType;
  final bool isFavorite;
  final bool showAllPrices;
  final double? minPrice;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const StationCard({
    super.key,
    required this.station,
    required this.fuelType,
    required this.isFavorite,
    required this.showAllPrices,
    this.minPrice,
    required this.onTap,
    required this.onFavorite,
  });

  Color _getPriceColor(double price) {
    if (minPrice == null || minPrice! <= 0) {
      if (price <= 1.70) return AppColors.cheap;
      if (price <= 1.85) return AppColors.medium;
      return AppColors.expensive;
    }

    if (price <= minPrice! + 0.001) return AppColors.cheap; // Lowest
    if (price <= minPrice! + 0.10) {
      return AppColors.medium; // Up to 10 cents more
    }
    return AppColors.expensive; // More than 10 cents more
  }

  Future<void> _openGoogleMaps() async {
    final lat = station.latitude;
    final lng = station.longitude;
    final name = Uri.encodeComponent(station.name);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = station.getPriceForType(fuelType);
    final priceColor =
        price != null ? _getPriceColor(price) : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top row: logo + info + price ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand icon
                    BrandIcon(brand: station.brand),
                    const SizedBox(width: 12),

                    // Name + info
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  station.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: station.isOpen
                                      ? AppColors.cheap.withValues(alpha: 0.2)
                                      : AppColors.expensive
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: station.isOpen
                                        ? AppColors.cheap
                                        : AppColors.expensive,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  station.isOpen ? 'Offen' : 'Zu',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: station.isOpen
                                        ? AppColors.cheap
                                        : AppColors.expensive,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${station.address}, ${station.city}',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                '${station.distanceKm.toStringAsFixed(1)} km',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time_rounded,
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                station.getTimeAgo,
                                style: GoogleFonts.outfit(
                                    fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Price
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: PriceDisplay(
                              price: price,
                              fontSize: 26,
                              color: priceColor,
                            ),
                          ),
                          if (price != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'EUR/L',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: priceColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons
                                      .trending_down_rounded, // Simple indicator
                                  size: 14,
                                  color: AppColors.cheap.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fuelType.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ────────────────────────────────────────────────────
              const Divider(
                height: 1,
                color: AppColors.divider,
                indent: 14,
                endIndent: 14,
              ),

              // ── Bottom action bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniPriceOrDash('Diesel', station.diesel),
                          _miniPriceOrDash('E5', station.e5),
                          _miniPriceOrDash('E10', station.e10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Google Maps navigation button
                        GestureDetector(
                          onTap: _openGoogleMaps,
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Favorite button
                        GestureDetector(
                          onTap: onFavorite,
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isFavorite
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color:
                                  isFavorite ? Colors.red : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPrice(String label, double price) {
    final color = _getPriceColor(price);
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white, // Bright white
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          PriceDisplay(
            price: price,
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _miniPriceOrDash(String label, double? price) {
    if (price == null) {
      return Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white, // Bright white
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '--',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    return _miniPrice(label, price);
  }
}

// ─── Brand Icon ────────────────────────────────────────────────────────────────
class BrandIcon extends StatelessWidget {
  final String brand;
  const BrandIcon({super.key, required this.brand});

  static const Map<String, BrandStyle> _brands = {
    // ─── Major Brands ───────────────────────────────────────────────
    'aral': BrandStyle(Color(0xFF003DA5), Color(0xFFFFFF00), 'ARAL'),
    'shell': BrandStyle(Color(0xFFDD1D21), Color(0xFFFFB900), 'SHELL'),
    'bp': BrandStyle(Color(0xFF006B3F), Color(0xFFFFFFFF), 'BP'),
    'esso': BrandStyle(Color(0xFF003087), Color(0xFFFF0000), 'ESSO'),
    'jet': BrandStyle(Color(0xFFFFCC00), Color(0xFF000000), 'JET'),
    'total': BrandStyle(Color(0xFFED1C24), Color(0xFFFFFFFF), 'TTE'),
    'totalenergies': BrandStyle(Color(0xFFED1C24), Color(0xFFFFFFFF), 'TTE'),
    'agip': BrandStyle(Color(0xFFFFD100), Color(0xFF000000), 'AGIP'),
    'eni': BrandStyle(Color(0xFFFFD100), Color(0xFF1A5C2A), 'ENI'),
    // ─── Regional / Discount ────────────────────────────────────────
    'avia': BrandStyle(Color(0xFFE2001A), Color(0xFFFFFFFF), 'AVIA'),
    'omv': BrandStyle(Color(0xFF007A33), Color(0xFFFFFFFF), 'OMV'),
    'westfalen': BrandStyle(Color(0xFF003B71), Color(0xFFFFFFFF), 'WF'),
    'star': BrandStyle(Color(0xFFE30613), Color(0xFFFFFFFF), 'STAR'),
    'hem': BrandStyle(Color(0xFF009639), Color(0xFFFFFFFF), 'HEM'),
    'hoyer': BrandStyle(Color(0xFFE30613), Color(0xFFFFFFFF), 'HOY'),
    'sprint': BrandStyle(Color(0xFFE31E24), Color(0xFFFFFFFF), 'SPR'),
    'tamoil': BrandStyle(Color(0xFF004F9E), Color(0xFFFFFFFF), 'TAM'),
    'classic': BrandStyle(Color(0xFFE30613), Color(0xFFFFFFFF), 'CLS'),
    'oil!': BrandStyle(Color(0xFFF7931E), Color(0xFFFFFFFF), 'OIL!'),
    'baywa': BrandStyle(Color(0xFF008A45), Color(0xFFFFFFFF), 'BWA'),
    'raiffeisen': BrandStyle(Color(0xFF004B23), Color(0xFFFFFFFF), 'RFN'),
    'globus': BrandStyle(Color(0xFFF39200), Color(0xFFFFFFFF), 'GLB'),
    'q1': BrandStyle(Color(0xFFE30613), Color(0xFFFFFFFF), 'Q1'),
    'bft': BrandStyle(Color(0xFF005293), Color(0xFFFFFFFF), 'BFT'),
    'markant': BrandStyle(Color(0xFFE30613), Color(0xFFFFFFFF), 'MKT'),
    'team': BrandStyle(Color(0xFF00549F), Color(0xFFFFFFFF), 'TEAM'),
    'ed': BrandStyle(Color(0xFF003DA5), Color(0xFFFFFF00), 'ED'),
    // ─── Supermarket Stations ────────────────────────────────────────
    'tank': BrandStyle(Color(0xFF0066CC), Color(0xFFFFFFFF), 'TNK'),
    'aldi': BrandStyle(Color(0xFF005293), Color(0xFFFFDB00), 'ALDI'),
    'lidl': BrandStyle(Color(0xFF0050AA), Color(0xFFFFCC00), 'LIDL'),
    'rewe': BrandStyle(Color(0xFFCC0000), Color(0xFFFFFFFF), 'REWE'),
    'penny': BrandStyle(Color(0xFFCC0000), Color(0xFFFFFF00), 'PNY'),
    'kaufland': BrandStyle(Color(0xFFCC0000), Color(0xFFFFFFFF), 'KFL'),
    'netto': BrandStyle(Color(0xFFFF0000), Color(0xFFFFFF00), 'NTO'),
    'tankpool': BrandStyle(Color(0xFF1565C0), Color(0xFFFFFFFF), 'TP24'),
    'supermarkt': BrandStyle(Color(0xFF388E3C), Color(0xFFFFFFFF), 'MKT'),
    'edeka': BrandStyle(Color(0xFFE30613), Color(0xFFFFFF00), 'EKA'),
    // ─── Others ──────────────────────────────────────────────────────
    'freie': BrandStyle(Color(0xFF37474F), Color(0xFF80CBC4), 'FREI'),
    'orlen': BrandStyle(Color(0xFFD80202), Color(0xFFFFFFFF), 'ORL'),
    'roth': BrandStyle(Color(0xFF1B5E20), Color(0xFFFFFFFF), 'RTH'),
    'score': BrandStyle(Color(0xFF0D47A1), Color(0xFFFFFFFF), 'SCR'),
    'nordoel': BrandStyle(Color(0xFF006AA7), Color(0xFFFFFFFF), 'NÖL'),
    'sas': BrandStyle(Color(0xFF1565C0), Color(0xFFFFFFFF), 'SAS'),
    'calpam': BrandStyle(Color(0xFF0D47A1), Color(0xFFFFD600), 'CAL'),
    'rath': BrandStyle(Color(0xFF4CAF50), Color(0xFFFFFFFF), 'RTH'),
    'walther': BrandStyle(Color(0xFF795548), Color(0xFFFFFFFF), 'WLT'),
    'löwa': BrandStyle(Color(0xFF1565C0), Color(0xFFFFFFFF), 'LWA'),
  };

  @override
  Widget build(BuildContext context) {
    final key = brand.toLowerCase().trim();
    final style = _brands.entries
        .firstWhere(
          (e) => key.contains(e.key),
          orElse: () => const MapEntry(
              '_', BrandStyle(Color(0xFF1F2E3E), Color(0xFF39FF14), null)),
        )
        .value;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: style.bg,
        border: Border.all(color: AppColors.border),
      ),
      child: style.abbr != null
          ? Center(
              child: Text(
                style.abbr!,
                style: GoogleFonts.outfit(
                  fontSize: style.abbr!.length > 3 ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  color: style.fg,
                  letterSpacing: -0.5,
                ),
              ),
            )
          : const Icon(
              Icons.local_gas_station_rounded,
              color: AppColors.primary,
              size: 24,
            ),
    );
  }
}

class BrandStyle {
  final Color bg;
  final Color fg;
  final String? abbr;
  const BrandStyle(this.bg, this.fg, this.abbr);
}
