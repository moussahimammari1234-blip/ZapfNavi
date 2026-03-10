import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../models/fuel_station.dart';
import '../../providers/app_providers.dart';
import '../../widgets/price_display.dart';
import 'package:share_plus/share_plus.dart';

class GasStationDetailScreen extends StatefulWidget {
  final FuelStation station;
  const GasStationDetailScreen({super.key, required this.station});

  @override
  State<GasStationDetailScreen> createState() => _GasStationDetailScreenState();
}

class _GasStationDetailScreenState extends State<GasStationDetailScreen> {
  String _selectedFuel = 'e5';
  bool _hasVerified = false;
  late int _verificationCount;

  @override
  void initState() {
    super.initState();
    _selectedFuel = context.read<FuelProvider>().selectedFuelType;
    // Start with 0 (real data)
    _verificationCount = 0;
  }

  void _verifyPrice() {
    setState(() {
      _hasVerified = true;
      _verificationCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vielen Dank für deine Bestätigung! ✅'),
        backgroundColor: AppColors.cheap,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final lat = widget.station.latitude;
    final lng = widget.station.longitude;
    final name = Uri.encodeComponent(widget.station.name);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareStation() {
    final s = widget.station;
    final fuelType = context.read<FuelProvider>().selectedFuelType;
    final price = s.getPriceForType(fuelType);

    String text = '⛽ ${s.name}\n📍 ${s.address}, ${s.city}\n';
    if (price != null) {
      text += '💰 ${fuelType.toUpperCase()}: ${price.toStringAsFixed(3)} €/L\n';
    }
    text += '🕐 Aktualisiert: ${s.getTimeAgo}\n';
    text += '\nGünstig tanken mit ZapfNavi!';

    Share.share(text,
        subject:
            '⛽ ${s.name} – ${fuelType.toUpperCase()} ${price != null ? '${price.toStringAsFixed(3)} €/L' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildPriceGrid(),
                const SizedBox(height: 16),
                _buildInfoSection(),
                const SizedBox(height: 16),
                _buildCommunityVerification(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigateButton(context),
    );
  }

  Widget _buildCommunityVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasVerified ? AppColors.cheap : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Left: icon + text
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _hasVerified
                    ? AppColors.cheap.withValues(alpha: 0.15)
                    : AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _hasVerified
                    ? Icons.verified_rounded
                    : Icons.help_outline_rounded,
                color: _hasVerified ? AppColors.cheap : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preis korrekt?',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _hasVerified
                        ? 'Du hast diesen Preis bestätigt ✅'
                        : '$_verificationCount Nutzer haben dies bestätigt',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color:
                          _hasVerified ? AppColors.cheap : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right: Ja / Bestätigt button with dark background
            GestureDetector(
              onTap: _hasVerified ? null : _verifyPrice,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _hasVerified ? AppColors.cheap : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_hasVerified ? AppColors.cheap : AppColors.primary)
                              .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasVerified
                          ? Icons.check_circle_rounded
                          : Icons.thumb_up_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasVerified ? 'Bestätigt' : 'Ja',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isFav = context.watch<FuelProvider>().isFavorite(widget.station.id);

    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            widget.station.name,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            widget.station.address,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? AppColors.expensive : AppColors.textSecondary,
          ),
          onPressed: () =>
              context.read<FuelProvider>().toggleFavorite(widget.station),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary),
          onPressed: _shareStation,
        ),
      ],
    );
  }

  Widget _buildPriceGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: widget.station.isOpen
                      ? AppColors.cheap.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.station.isOpen ? '● Geöffnet' : '● Geschlossen',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.station.isOpen
                        ? AppColors.cheap
                        : AppColors.expensive,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              Text(
                ' ${widget.station.distanceKm.toStringAsFixed(1)} km entfernt',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Preise aktualisiert: ${widget.station.getTimeAgo}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Always show all 3 fuel type price cards
              _priceCard('Diesel', widget.station.diesel),
              _priceCard('E5', widget.station.e5),
              _priceCard('E10', widget.station.e10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String type, double? price) {
    final isSelected = _selectedFuel == type.toLowerCase();
    Color color = AppColors.textMuted;
    if (price != null) {
      if (price <= 1.70) {
        color = AppColors.cheap;
      } else if (price <= 1.80) {
        color = AppColors.medium;
      } else {
        color = AppColors.expensive;
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFuel = type.toLowerCase()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGlow : AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                type,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white, // Bright white
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              PriceDisplay(
                price: price,
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.w800,
              ),
              Text(
                price != null ? '€/L' : '-',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _infoRow(
              Icons.schedule_rounded,
              'Öffnungszeiten',
              widget.station.openingHours ?? '24h geöffnet',
            ),
            const Divider(color: AppColors.divider),
            _infoRow(
              Icons.location_on_rounded,
              'Adresse',
              '${widget.station.address}, ${widget.station.city}',
            ),
            const Divider(color: AppColors.divider),
            _infoRow(
              Icons.local_shipping_rounded,
              'LKW geeignet',
              widget.station.hasTruck ? 'Ja' : 'Nein',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigateButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openGoogleMaps,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              minimumSize: const Size(double.infinity, 56),
            ),
            icon: const Icon(Icons.navigation_rounded, color: Colors.white),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Navigation starten',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
