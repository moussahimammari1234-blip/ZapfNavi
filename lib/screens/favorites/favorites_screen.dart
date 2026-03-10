import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/station_card.dart';
import '../home/gas_station_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fuelProvider = context.watch<FuelProvider>();
    final favorites = fuelProvider.favorites;

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
        title: Text('Favoriten',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: favorites.isEmpty
          ? _buildEmpty()
          : _buildList(context, favorites, fuelProvider),
    );
  }

  Widget _buildList(
    BuildContext context,
    List favorites,
    FuelProvider fuelProvider,
  ) {
    final List<Widget> items = [];
    for (int i = 0; i < favorites.length; i++) {
      final station = favorites[i];

      items.add(
        Dismissible(
          key: Key('fav_swipe_${station.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.expensive,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_sweep_rounded,
                color: Colors.white, size: 28),
          ),
          onDismissed: (_) {
            fuelProvider.toggleFavorite(station);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${station.name} entfernt')),
            );
          },
          child: StationCard(
            station: station,
            fuelType: fuelProvider.selectedFuelType,
            showAllPrices: fuelProvider.showAllPrices,
            isFavorite: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GasStationDetailScreen(station: station),
                ),
              );
            },
            onFavorite: () {
              fuelProvider.toggleFavorite(station);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${station.name} entfernt')),
              );
            },
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          Text('Noch keine Favoriten',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(
              'Tippe auf das Herz-Symbol bei einer Tankstelle\num sie zu speichern.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.white70, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
