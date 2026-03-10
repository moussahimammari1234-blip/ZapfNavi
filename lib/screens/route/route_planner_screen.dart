import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/app_providers.dart';
import '../../app/theme.dart';
import '../../models/fuel_station.dart';
import '../home/gas_station_detail_screen.dart';
import '../../widgets/station_card.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final _startController = TextEditingController();
  final _zielController = TextEditingController();
  bool _avoidHighway = false;
  bool _isLoading = false;
  String? _errorMsg;
  bool _hasSearched = false;

  // Sort mode for the result list
  String _sortMode = 'price'; // price | distance

  double? _startLat, _startLng, _destLat, _destLng;

  @override
  void dispose() {
    _startController.dispose();
    _zielController.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    final startText = _startController.text.trim();
    final zielText = _zielController.text.trim();

    if (startText.isEmpty || zielText.isEmpty) {
      setState(() => _errorMsg = 'Bitte Start und Ziel eingeben.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _hasSearched = false;
    });

    try {
      var startLocs = await locationFromAddress('$startText, Deutschland')
          .catchError((_) => <Location>[]);
      var zielLocs = await locationFromAddress('$zielText, Deutschland')
          .catchError((_) => <Location>[]);

      if (startLocs.isEmpty) {
        startLocs = await locationFromAddress(startText)
            .catchError((_) => <Location>[]);
      }
      if (zielLocs.isEmpty) {
        zielLocs =
            await locationFromAddress(zielText).catchError((_) => <Location>[]);
      }

      if (startLocs.isEmpty || zielLocs.isEmpty) {
        setState(
            () => _errorMsg = 'Adresse nicht gefunden. Prüfe deine Eingabe.');
        return;
      }

      _startLat = startLocs.first.latitude;
      _startLng = startLocs.first.longitude;
      _destLat = zielLocs.first.latitude;
      _destLng = zielLocs.first.longitude;

      if (!mounted) return;
      final fuelProvider = context.read<FuelProvider>();

      await fuelProvider.loadStationsAlongRoute(
        startLat: _startLat!,
        startLng: _startLng!,
        destLat: _destLat!,
        destLng: _destLng!,
      );

      setState(() => _hasSearched = true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'Fehler beim Suchen der Orte: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openFullRoute() async {
    if (_startLat == null || _destLat == null) return;
    final avoidParam = _avoidHighway ? '&avoid=highways' : '';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$_startLat,$_startLng'
      '&destination=$_destLat,$_destLng'
      '&travelmode=driving$avoidParam',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<FuelStation> _getSortedStations(List<FuelStation> stations) {
    final fuelProvider = context.read<FuelProvider>();
    final fuelType = fuelProvider.selectedFuelType;
    final list = List<FuelStation>.from(stations);

    if (_sortMode == 'price') {
      list.sort((a, b) {
        final pa = a.getPriceForType(fuelType) ?? double.infinity;
        final pb = b.getPriceForType(fuelType) ?? double.infinity;
        return pa.compareTo(pb);
      });
    } else {
      // Sort by distance from start
      if (_startLat != null && _startLng != null) {
        list.sort((a, b) {
          final da = Geolocator.distanceBetween(
              _startLat!, _startLng!, a.latitude, a.longitude);
          final db = Geolocator.distanceBetween(
              _startLat!, _startLng!, b.latitude, b.longitude);
          return da.compareTo(db);
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Routenplaner',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Input Area (fixed at top) ──────────────────────────────
          _buildInputCard(),

          // ── Results Area (scrollable) ──────────────────────────────
          Expanded(
            child: Consumer<FuelProvider>(
              builder: (context, fuelProvider, _) {
                if (_isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Suche Tankstellen auf der Route...',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                if (!_hasSearched) {
                  return _buildEmptyState();
                }

                // ─── Use routeStations (separate list, not affected by other screens)
                if (fuelProvider.routeStations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_gas_station_outlined,
                            color: AppColors.textMuted, size: 60),
                        const SizedBox(height: 12),
                        Text('Keine Tankstellen auf der Route gefunden.',
                            style: GoogleFonts.outfit(
                                color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                            'Versuche einen anderen Start oder ein anderes Ziel.',
                            style: GoogleFonts.outfit(
                                color: AppColors.textMuted, fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final sorted = _getSortedStations(fuelProvider.routeStations);

                return Column(
                  children: [
                    // Summary + Sort bar
                    _buildResultsHeader(
                        sorted.length, fuelProvider.selectedFuelType, sorted),
                    // Full-route navigation button
                    _buildFullRouteButton(),
                    // Price list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final station = sorted[index];

                          return StationCard(
                            station: station,
                            fuelType: fuelProvider.selectedFuelType,
                            showAllPrices: fuelProvider.showAllPrices,
                            isFavorite: fuelProvider.isFavorite(station.id),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GasStationDetailScreen(station: station),
                                ),
                              );
                            },
                            onFavorite: () {
                              fuelProvider.toggleFavorite(station);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        fuelProvider.isFavorite(station.id)
                                            ? '${station.name} gemerkt'
                                            : '${station.name} entfernt')),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Card ────────────────────────────────────────────────────────────
  Widget _buildInputCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Start field
          _inputField(
            controller: _startController,
            hint: 'Start: z.B. München oder 80331',
            icon: Icons.radio_button_checked_rounded,
            iconColor: AppColors.cheap,
          ),
          // Dashed connector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 20),
                ...List.generate(
                    4,
                    (i) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            height: 1.5,
                            color: i % 2 == 0
                                ? AppColors.border
                                : Colors.transparent,
                          ),
                        )),
              ],
            ),
          ),
          // Ziel field
          _inputField(
            controller: _zielController,
            hint: 'Ziel: z.B. Hamburg oder 20095',
            icon: Icons.location_on_rounded,
            iconColor: AppColors.expensive,
          ),
          const SizedBox(height: 12),

          // Avoid highway row
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _avoidHighway = !_avoidHighway),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 20,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _avoidHighway
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _avoidHighway
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _avoidHighway
                                ? AppColors.background
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Autobahn vermeiden',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search button row - now on its own row for better spacing
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _startNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.buttonText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.black))
                  : const Icon(Icons.search_rounded, size: 24),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_isLoading ? 'Suche...' : 'Suchen',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expensive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.expensive, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_errorMsg!,
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppColors.expensive))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: iconColor, size: 18),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.route_rounded,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Route eingeben',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Gib Start und Ziel ein.\nWir zeigen dir alle Tankstellen auf der Route sortiert nach Preis.',
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Results Header + Sort ─────────────────────────────────────────────────
  Widget _buildResultsHeader(
      int count, String fuelType, List<FuelStation> sorted) {
    final cheapest =
        sorted.isNotEmpty ? sorted.first.getPriceForType(fuelType) : null;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          // Count + cheapest price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Tankstellen gefunden',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                if (cheapest != null)
                  Text(
                    'Günstigster: ${cheapest.toStringAsFixed(3)} €',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.cheap),
                  ),
              ],
            ),
          ),
          // Sort toggle
          GestureDetector(
            onTap: () => setState(
                () => _sortMode = _sortMode == 'price' ? 'distance' : 'price'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _sortMode == 'price' ? 'Preis ↑' : 'Distanz ↑',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Full Route Navigation Button ──────────────────────────────────────────
  Widget _buildFullRouteButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _openFullRoute,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.navigation_rounded,
              size: 20, color: Colors.white),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Gesamte Route in Google Maps öffnen',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
