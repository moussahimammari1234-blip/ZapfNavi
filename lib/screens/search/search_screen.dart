import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/app_providers.dart';
// No ads in Filter & Suche screen (P0 compliance)
import '../../services/location_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Local filter state — use provider values as defaults
  late double _radius;
  late bool _onlyOpen;
  late bool _onlyTruck;
  late String _sortBy;
  late String _fuelType;
  late bool _showAllPrices;

  String _selectedBrand = 'Alle';

  bool _initialized = false;

  // Autocomplete state
  List<LocationSuggestion> _suggestions = [];
  bool _isSearchingSuggestions = false;
  Timer? _debounceTimer;
  LocationSuggestion? _selectedSuggestion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Safe defaults — overridden synchronously in didChangeDependencies
    _radius = 5.0;
    _onlyOpen = false;
    _onlyTruck = false;
    _sortBy = 'price';
    _fuelType = 'e5';
    _showAllPrices = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final fp = context.read<FuelProvider>();
      _radius = fp.searchRadius;
      _onlyOpen = fp.showOnlyOpen;
      _sortBy = fp.sortBy;
      _fuelType = fp.selectedFuelType;
      _showAllPrices = fp.showAllPrices;
      _searchController.text = fp.searchQuery;
      _selectedBrand = fp.selectedBrand;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length < 3) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }

      if (mounted) setState(() => _isSearchingSuggestions = true);
      final suggestions = await LocationService().getSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isSearchingSuggestions = false;
        });
      }
    });
  }

  void _apply(FuelProvider fp) {
    fp.batchUpdate(
      radius: _radius,
      showOnlyOpen: _onlyOpen,
      sortBy: _sortBy,
      fuelType: _fuelType,
      searchQuery: _searchController.text,
      brand: _selectedBrand,
      targetLat: _selectedSuggestion?.lat,
      targetLng: _selectedSuggestion?.lng,
      targetCity: _selectedSuggestion?.city,
      showAllPrices: _showAllPrices,
    );
    Navigator.pop(context);
  }

  void _reset(FuelProvider fp) {
    setState(() {
      _radius = 5.0;
      _onlyOpen = false;
      _onlyTruck = false;
      _sortBy = 'price';
      _fuelType = 'e5';
      _selectedBrand = 'Alle';
      _showAllPrices = false;
    });
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FuelProvider>();
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(fp),
      body: Column(
        children: [
          // Tab header
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFilterTab(fp, isPremium),
                _buildSortTab(fp, isPremium),
                _buildBrandTab(isPremium),
              ],
            ),
          ),
          _buildApplyBar(fp),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(FuelProvider fp) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Filter & Suche',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _reset(fp),
          child: Text(
            'Zurücksetzen',
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Filter'),
          Tab(text: 'Sortierung'),
          Tab(text: 'Marken'),
        ],
      ),
    );
  }

  // ─── Filter Tab ───────────────────────────────────────────────────────────────
  Widget _buildFilterTab(FuelProvider fp, bool isPremium) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Search field
        _sectionLabel('Tankstelle suchen'),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Name, Straße oder Stadt...',
            hintStyle:
                GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _suggestions = [];
                      _selectedSuggestion = null;
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
        if (_isSearchingSuggestions)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              minHeight: 2,
            ),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 18),
                  title: Text(
                    s.label,
                    style: GoogleFonts.outfit(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _searchController.text = s.city;
                      _selectedSuggestion = s;
                      _suggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 26),

        // Kraftstoffart
        _sectionLabel('Kraftstoffart'),
        const SizedBox(height: 12),
        Row(
          children: [
            _fuelChip('Diesel', 'diesel', Icons.oil_barrel_rounded,
                const Color(0xFFFF8C00)),
            const SizedBox(width: 10),
            _fuelChip('E5 (Super)', 'e5', Icons.local_gas_station_rounded,
                const Color(0xFF2196F3)),
            const SizedBox(width: 10),
            _fuelChip('E10', 'e10', Icons.eco_rounded, const Color(0xFF4CAF50)),
          ],
        ),
        const SizedBox(height: 26),

        // Suchradius
        _sectionLabel('Suchradius: ${_radius.toInt()} km'),
        const SizedBox(height: 4),
        // Radius marks
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['1', '5', '10', '15', '20', '25'].map((km) {
            final v = double.parse(km);
            final active = _radius.toInt() == v.toInt();
            return GestureDetector(
              onTap: () => setState(() => _radius = v),
              child: Container(
                width: 38,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryGlow : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  '$km km',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primaryGlow,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _radius,
            min: 1,
            max: 25,
            divisions: 24,
            onChanged: (v) => setState(() => _radius = v),
          ),
        ),

        // No ads in filter tabs (store/UX compliance)

        const SizedBox(height: 26),

        // Filter-Schalter
        _sectionLabel('Optionen'),
        const SizedBox(height: 12),
        _filterToggle(
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF00E676),
          title: 'Nur geöffnete anzeigen',
          subtitle: 'Tankstellen die jetzt geöffnet sind',
          value: _onlyOpen,
          onChanged: (v) => setState(() => _onlyOpen = v),
        ),
        const SizedBox(height: 10),
        _filterToggle(
          icon: Icons.local_shipping_rounded,
          iconColor: const Color(0xFF2196F3),
          title: 'LKW-freundlich',
          subtitle: 'Nur Stationen mit LKW-Bereich',
          value: _onlyTruck,
          onChanged: (v) => setState(() => _onlyTruck = v),
        ),
        const SizedBox(height: 10),
        // Price range as info card
        _infoCard(
          icon: Icons.euro_rounded,
          iconColor: const Color(0xFFFFD600),
          title: 'Preistrend heute',
          subtitle: 'Günstig: < 1.70€ · Mittel: 1.70–1.85€ · Teuer: > 1.85€',
        ),
      ],
    );
  }

  // ─── Sort Tab ─────────────────────────────────────────────────────────────────
  Widget _buildSortTab(FuelProvider fp, bool isPremium) {
    final options = [
      (
        'Günstigstes zuerst',
        'price',
        Icons.euro_rounded,
        'Sortiert nach Preis aufsteigend'
      ),
      (
        'Nächstes zuerst',
        'distance',
        Icons.near_me_rounded,
        'Sortiert nach Entfernung'
      ),
      (
        'Name (A–Z)',
        'name',
        Icons.sort_by_alpha_rounded,
        'Alphabetisch nach Name'
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionLabel('Nach was sortieren?'),
        const SizedBox(height: 14),
        ...options.map((opt) {
          final (label, key, icon, desc) = opt;
          final selected = _sortBy == key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _sortBy = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryGlow : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color:
                            selected ? AppColors.primary : AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _filterToggle(
          icon: Icons.list_alt_rounded,
          iconColor: const Color(0xFF9C27B0),
          title: 'Alle Preise anzeigen',
          subtitle: 'Diesel, E5 und E10 nebeneinander',
          value: _showAllPrices,
          onChanged: (v) => setState(() => _showAllPrices = v),
        ),
      ],
    );
  }

  // ─── Brand Tab ────────────────────────────────────────────────────────────────
  Widget _buildBrandTab(bool isPremium) {
    final brands = [
      ('Alle', null, AppColors.primary),
      ('Aral', const Color(0xFF003DA5), Colors.white),
      ('Shell', const Color(0xFFDD1D21), const Color(0xFFFFB900)),
      ('BP', const Color(0xFF006B3F), Colors.white),
      ('ESSO', const Color(0xFF003087), const Color(0xFFFF0000)),
      ('JET', const Color(0xFFE31837), Colors.white),
      ('Total', const Color(0xFFED1C24), Colors.white),
      ('Agip', Colors.black, const Color(0xFFE20714)),
      ('STAR', const Color(0xFFFFD700), Colors.black),
      ('HEM', const Color(0xFFFF6B00), Colors.white),
      ('Hoyer', const Color(0xFF0066CC), Colors.white),
      ('Westfalen', const Color(0xFF003B71), Colors.white),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionLabel('Marke auswählen'),
        const SizedBox(height: 6),
        Text(
          'Filtern Sie nach einer bestimmten Tankstellenmarke',
          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: brands.map((b) {
            final (name, bg, fg) = b;
            final selected = _selectedBrand == name;
            return GestureDetector(
              onTap: () => setState(() => _selectedBrand = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? (bg ?? AppColors.primaryGlow)
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected ? (bg ?? AppColors.primary) : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bg != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? (fg) : AppColors.textSecondary,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 5),
                      Icon(Icons.check_rounded, size: 14, color: fg),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _infoCard(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.textMuted,
          title: 'Hinweis',
          subtitle: 'Markenfilter basiert auf verfügbaren Daten in Ihrer Nähe.',
        ),
      ],
    );
  }

  // ─── Apply Bar ────────────────────────────────────────────────────────────────
  Widget _buildApplyBar(FuelProvider fp) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Result count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${fp.stations.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Treffer',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Apply button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _apply(fp),
                icon: const Icon(Icons.done_all_rounded, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Filter anwenden',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _fuelChip(String label, String type, IconData icon, Color accent) {
    final selected = _fuelType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fuelType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.15) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? accent : AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: value
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
