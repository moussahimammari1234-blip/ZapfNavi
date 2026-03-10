import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/fuel_station.dart';
import '../../providers/app_providers.dart';

import '../../widgets/price_display.dart';
import '../../widgets/station_card.dart';
import '../home/gas_station_detail_screen.dart';
import '../search/search_screen.dart';
import '../favorites/favorites_screen.dart';
import '../price_alarm/price_alarm_screen.dart';
import '../route/route_planner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/settings_screen.dart';
import 'location_permission_screen.dart';
import 'package:geolocator/geolocator.dart';

class MainFuelScreen extends StatefulWidget {
  const MainFuelScreen({super.key});

  @override
  State<MainFuelScreen> createState() => _MainFuelScreenState();
}

class _MainFuelScreenState extends State<MainFuelScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _fabController;

  final List<Widget> _screens = const [_FuelListView(), _MapView()];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initial check and load
    WidgetsBinding.instance.addPostFrameCallback((_) => _initApp());
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsented = prefs.getBool('gdpr_consented') ?? false;

    if (!hasConsented && mounted) {
      _showPermissionScreen(prefs);
      return;
    }

    if (!mounted) return;

    // Check if location permission is granted
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showPermissionScreen(prefs);
      return;
    }

    // Check if GPS service is enabled — handled by FuelProvider which
    // shows a _GpsDisabledView if GPS is off. No dialog needed here.
  }

  void _showPermissionScreen(SharedPreferences prefs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPermissionScreen(
          onPermissionGranted: () {
            prefs.setBool('gdpr_consented', true);
            Navigator.pop(context);
            context.read<FuelProvider>().loadStations();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = context.watch<PremiumProvider>();
    final isPremium = premiumProvider.isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isPremium),
      floatingActionButton:
          _selectedTab == 0 && !context.watch<FuelProvider>().isGpsDisabled
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.buttonText,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                    'Filtern',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
    );
  }

  Widget _buildBottomNav(bool isPremium) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.local_gas_station_rounded,
                'Tanken',
                0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _navItem(
                Icons.map_rounded,
                'Karte',
                1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              _navItem(
                Icons.route_rounded,
                'Route',
                2,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutePlannerScreen()),
                ),
              ),
              _navItem(
                Icons.search_rounded,
                'Suche',
                3,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
              ),
              _navItem(
                Icons.settings_rounded,
                'Einstellungen',
                4,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedTab == index;
    final itemColor =
        color ?? (isSelected ? AppColors.primary : AppColors.textMuted);

    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: itemColor, size: 24),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: itemColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Fuel List View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FuelListView extends StatelessWidget {
  const _FuelListView();

  @override
  Widget build(BuildContext context) {
    final fuelProvider = context.watch<FuelProvider>();
    final premiumProvider = context.watch<PremiumProvider>();

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, fuelProvider),
        SliverToBoxAdapter(
          child: _buildFuelTypeSelector(context, fuelProvider),
        ),
        if (fuelProvider.isGpsDisabled)
          const SliverFillRemaining(child: _GpsDisabledView())
        else if (fuelProvider.isLoading)
          const SliverFillRemaining(child: _LoadingView())
        else if (fuelProvider.error != null)
          SliverFillRemaining(child: _ErrorView(error: fuelProvider.error!))
        else
          _buildStationList(context, fuelProvider, premiumProvider),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, FuelProvider fuelProvider) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: AppColors.background,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      title: Row(
        children: [
          // City search button — tap to open filter/search screen
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fuelProvider.currentCity.isNotEmpty
                                ? fuelProvider.currentCity
                                : 'Stadt suchen...',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${fuelProvider.searchRadius.toInt()} km · '
                            '${fuelProvider.stations.length} Tankstellen',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fuelProvider.isLocating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      const Icon(Icons.tune_rounded,
                          color: AppColors.textMuted, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── Favoriten Button ──────────────────────────────────────
          _appBarIcon(
            context,
            icon: Icons.favorite_rounded,
            color: AppColors.expensive,
            tooltip: 'Favoriten',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          const SizedBox(width: 6),
          // ── Preisalarm Button ─────────────────────────────────────
          _appBarIcon(
            context,
            icon: Icons.notifications_active_rounded,
            color: context.watch<AppProvider>().priceAlertsEnabled
                ? AppColors.primary
                : Colors.white70,
            tooltip: 'Preisalarm',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PriceAlarmScreen()),
            ),
          ),
          const SizedBox(width: 6),
          // GPS / Reload button
          _appBarIcon(
            context,
            icon: Icons.my_location_rounded,
            color:
                fuelProvider.isGpsDisabled ? Colors.white70 : AppColors.primary,
            tooltip: 'Standort aktualisieren',
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suche Standort...'),
                  duration: Duration(seconds: 2),
                ),
              );
              await fuelProvider.determinePosition();
              await fuelProvider.loadStations();
            },
          ),
        ],
      ),
      titleSpacing: 12,
    );
  }

  Widget _appBarIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }

  Widget _buildFuelTypeSelector(BuildContext context, FuelProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _fuelChip(context, provider, 'Diesel', 'diesel')),
              const SizedBox(width: 8),
              Expanded(child: _fuelChip(context, provider, 'Super E5', 'e5')),
              const SizedBox(width: 8),
              Expanded(child: _fuelChip(context, provider, 'Super E10', 'e10')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fuelChip(
    BuildContext context,
    FuelProvider provider,
    String label,
    String type,
  ) {
    final isSelected = provider.selectedFuelType == type;
    return GestureDetector(
      onTap: () => provider.setFuelType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationList(
    BuildContext context,
    FuelProvider fuelProvider,
    PremiumProvider premiumProvider,
  ) {
    final stations = fuelProvider.stations;

    // --- Fix: Better loading state handling ---
    if (fuelProvider.isLoading || fuelProvider.isLocating) {
      return const SliverFillRemaining(
        child: _LoadingView(),
      );
    }

    if (stations.isEmpty) {
      return SliverFillRemaining(
        child: _ErrorView(error: 'Keine Tankstellen gefunden.'),
      );
    }

    // P0: "Günstigste Tankstelle" must be an OPEN station by default.
    // Prefer cheapest open station; fall back to cheapest overall only if all closed.
    final openStations = stations.where((s) => s.isOpen).toList();
    final topDeal =
        openStations.isNotEmpty ? openStations.first : stations.first;
    final allClosed = openStations.isEmpty;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // index 0 → Top Deal Banner
          if (index == 0) {
            return _TopDealBanner(
              station: topDeal,
              price: topDeal.getPriceForType(fuelProvider.selectedFuelType),
              fuelType: fuelProvider.selectedFuelType,
              showAllPrices: fuelProvider.showAllPrices,
              allClosed: allClosed,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GasStationDetailScreen(station: topDeal)),
                );
              },
            );
          }

          // No ads, index is directly stationIndex
          final stationIndex = index - 1;

          if (stationIndex >= stations.length) return null;
          final station = stations[stationIndex];
          return StationCard(
            station: station,
            fuelType: fuelProvider.selectedFuelType,
            showAllPrices: fuelProvider.showAllPrices,
            isFavorite: fuelProvider.isFavorite(station.id),
            minPrice: fuelProvider.minSelectedPrice,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GasStationDetailScreen(station: station),
                ),
              );
            },
            onFavorite: () => fuelProvider.toggleFavorite(station),
          );
        },
        childCount: stations.length + 1,
      ),
    );
  }
}

// ─── GPS Disabled View ───────────────────────────────────────────────────────
class _GpsDisabledView extends StatelessWidget {
  const _GpsDisabledView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing GPS icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.gps_off_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'GPS deaktiviert',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aktiviere deinen Standortdienst, um Tankstellen in deiner Nähe zu sehen.',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  // Auto-reload when GPS comes back
                  if (context.mounted) {
                    _waitAndReload(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                ),
                icon: const Icon(Icons.gps_fixed_rounded,
                    size: 20, color: Colors.white),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'GPS aktivieren',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _waitAndReload(BuildContext context) async {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!context.mounted) return;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        if (context.mounted) {
          context.read<FuelProvider>().retryAfterGps();
        }
        return;
      }
    }
  }
}

// ─── TOP DEAL Banner ────────────────────────────────────────────────────────
class _TopDealBanner extends StatefulWidget {
  final FuelStation station;
  final double? price;
  final String fuelType;
  final bool showAllPrices;
  final bool allClosed;
  final VoidCallback onTap;

  const _TopDealBanner({
    required this.station,
    required this.price,
    required this.fuelType,
    required this.showAllPrices,
    this.allClosed = false,
    required this.onTap,
  });

  @override
  State<_TopDealBanner> createState() => _TopDealBannerState();
}

class _TopDealBannerState extends State<_TopDealBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Container(
            constraints: const BoxConstraints(minHeight: 130),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF254F22), // User's requested green
                  Color(0xFF2E612A), // Slightly lighter variation
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF254F22)
                      .withValues(alpha: 0.2 + (_pulse.value * 0.15)),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
          child: Stack(
            children: [
              // Abstract background shapes
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BrandIcon(brand: widget.station.brand),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flash_on_rounded,
                                        color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'TOP DEAL',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Status badge for Top Deal
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.allClosed
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : Colors.green.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: widget.allClosed
                                        ? Colors.red
                                        : Colors.greenAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.allClosed ? 'Geschlossen' : 'Offen',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.station.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.allClosed
                                    ? 'Aktuell geschlossen'
                                    : widget.station.address,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.near_me_rounded,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${widget.station.distanceKm.toStringAsFixed(1)} km',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.access_time_rounded,
                                      size: 12, color: Colors.white70),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.station.getTimeAgo,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: PriceDisplay(
                                  price: widget.price,
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (widget.price != null)
                                Text(
                                  'EUR/L',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniPrice('Diesel', widget.station.diesel),
                        _miniPrice('E5', widget.station.e5),
                        _miniPrice('E10', widget.station.e10),
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

  Widget _miniPrice(String l, double? p) {
    return Column(
      children: [
        Text(l,
            style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        p == null
            ? Text('--',
                style: GoogleFonts.outfit(
                    color: Colors.white24, fontWeight: FontWeight.bold))
            : PriceDisplay(
                price: p,
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
      ],
    );
  }
}

// --- Map View with flutter_map + Pure-Dart Grid Clustering ----------------
class _MapView extends StatefulWidget {
  const _MapView();
  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  MapController? _mapController;
  FuelStation? _selected;
  double? _lastLat;
  double? _lastLng;
  double _currentZoom = 12;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Color _priceColor(double p) {
    if (p <= 1.70) return AppColors.cheap;
    if (p <= 1.85) return AppColors.medium;
    return AppColors.expensive;
  }

  // ── Clustering ────────────────────────────────────────────────────────────
  // Grid cell size in degrees, shrinks as zoom increases.
  // At zoom ~10 → 0.4° cells; zoom ~12 → 0.1°; zoom ≥ 13 → individual markers.
  double _cellSize(double zoom) {
    if (zoom >= 14) return 0.02;
    if (zoom >= 13) return 0.05;
    if (zoom >= 12) return 0.10;
    if (zoom >= 11) return 0.20;
    if (zoom >= 10) return 0.40;
    return 0.80;
  }

  /// Groups stations into clusters. Returns list of _MapCluster.
  List<_MapCluster> _computeClusters(
      List<FuelStation> stations, double zoom, String fuelType) {
    if (stations.isEmpty) return [];
    final cell = _cellSize(zoom);
    final Map<String, List<FuelStation>> grid = {};

    for (final s in stations) {
      final col = (s.longitude / cell).floor();
      final row = (s.latitude / cell).floor();
      final key = '$row:$col';
      grid.putIfAbsent(key, () => []).add(s);
    }

    return grid.entries.map((entry) {
      final members = entry.value;
      // Centroid
      final lat = members.map((s) => s.latitude).reduce((a, b) => a + b) /
          members.length;
      final lng = members.map((s) => s.longitude).reduce((a, b) => a + b) /
          members.length;
      // Cheapest price in cluster
      FuelStation? cheapest;
      double lowestPrice = 99.0;
      for (final m in members) {
        final p = m.getPriceForType(fuelType);
        if (p != null && p < lowestPrice) {
          lowestPrice = p;
          cheapest = m;
        }
      }
      return _MapCluster(
        lat: lat,
        lng: lng,
        stations: members,
        cheapest: cheapest,
        lowestPrice: cheapest != null ? lowestPrice : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FuelProvider>();
    final stations = fp.stations;
    final fuelType = fp.selectedFuelType;

    // Center map ONLY if location actually changed in provider
    if (_lastLat != fp.currentLat || _lastLng != fp.currentLng) {
      _lastLat = fp.currentLat;
      _lastLng = fp.currentLng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.move(LatLng(fp.currentLat, fp.currentLng), 12);
      });
    }

    final clusters = _computeClusters(stations, _currentZoom, fuelType);

    return Stack(
      children: [
        // --- The map ---
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(fp.currentLat, fp.currentLng),
            initialZoom: 12,
            maxZoom: 17,
            minZoom: 8,
            onMapEvent: (event) {
              if (event is MapEventMoveEnd ||
                  event is MapEventScrollWheelZoom ||
                  event is MapEventDoubleTapZoom) {
                final newZoom = _mapController?.camera.zoom ?? _currentZoom;
                if ((newZoom - _currentZoom).abs() > 0.3) {
                  setState(() {
                    _currentZoom = newZoom;
                    _selected = null; // deselect on zoom change
                  });
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.benzinsparren.de.app',
            ),
            MarkerLayer(
              rotate: true,
              markers: clusters.map((cluster) {
                final isCluster = cluster.stations.length > 1;
                final price = cluster.lowestPrice;
                final color =
                    price != null ? _priceColor(price) : AppColors.textMuted;
                final isSingle = !isCluster;
                final singleStation = isSingle ? cluster.stations.first : null;
                final isSelected =
                    isSingle && _selected?.id == singleStation?.id;

                if (isCluster) {
                  // ── Cluster bubble ──────────────────────────────────────
                  return Marker(
                    point: LatLng(cluster.lat, cluster.lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        // Zoom into cluster
                        final newZoom = (_currentZoom + 2.0).clamp(8.0, 17.0);
                        _mapController?.move(
                            LatLng(cluster.lat, cluster.lng), newZoom);
                        setState(() => _currentZoom = newZoom);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color.withValues(alpha: 0.9), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${cluster.stations.length}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                            if (price != null)
                              Text(
                                '${price.toStringAsFixed(2)}€',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // ── Single station marker ───────────────────────────────
                  return Marker(
                    point: LatLng(cluster.lat, cluster.lng),
                    width: 74,
                    height: 50,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selected = isSelected ? null : singleStation),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? color : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: color, width: isSelected ? 2 : 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(
                                      alpha: isSelected ? 0.45 : 0.2),
                                  blurRadius: isSelected ? 10 : 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              price != null
                                  ? '${price.toStringAsFixed(2)}€'
                                  : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: const Size(10, 6),
                            painter: _TrianglePainter(color),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }).toList(),
            ),
          ],
        ),

        // --- Selected station bottom card ---
        if (_selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GasStationDetailScreen(station: _selected!),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_gas_station_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selected!.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _selected!.address,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selected!.getPriceForType(fuelType) != null)
                          Text(
                            '${_selected!.getPriceForType(fuelType)!.toStringAsFixed(3)}€',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _priceColor(
                                  _selected!.getPriceForType(fuelType)!),
                            ),
                          ),
                        Text(
                          fuelType.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _selected = null),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // --- Floating title bar ---
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${stations.length} Tankstellen in ${fp.currentCity}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (fp.isLoading ||
                        (fp.currentCity == 'Berlin' && stations.isEmpty))
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.cheap,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Günstig',
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.medium,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Mittel',
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.expensive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Teuer',
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Loading & Error Views â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 60,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<FuelProvider>().loadStations(),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Cluster data ──────────────────────────────────────────────────────────
/// Represents a group of FuelStations within a map grid cell.
/// When stations.length == 1, drawn as an individual marker.
/// When stations.length > 1, drawn as a count bubble.
class _MapCluster {
  final double lat;
  final double lng;
  final List<FuelStation> stations;
  final FuelStation? cheapest;
  final double? lowestPrice;

  const _MapCluster({
    required this.lat,
    required this.lng,
    required this.stations,
    required this.cheapest,
    required this.lowestPrice,
  });
}
