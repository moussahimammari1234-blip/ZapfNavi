import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/app_providers.dart';
import '../legal/legal_screen.dart';
import '../faq/faq_screen.dart';
import '../../services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.expensive, size: 28),
            const SizedBox(width: 10),
            Text(
              'Konto löschen?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Alle deine Daten (Favoriten, Einstellungen) werden unwiderruflich gelöscht. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Abbrechen',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService().deleteAccount();
                // Clear local data
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Konto wurde gelöscht.',
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                      backgroundColor: AppColors.cheap,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Fehler beim Löschen: $e',
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                      backgroundColor: AppColors.expensive,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expensive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Endgültig löschen',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Einstellungen',
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: user == null
                ? Column(
                    children: [
                      const Icon(Icons.account_circle_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Nicht angemeldet',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.buttonText,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Anmelden'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                          border:
                              Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                user.userMetadata?['full_name'] ?? 'Nutzer',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              user.email ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (premiumProvider.isPremium)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGlow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Premium',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Benachrichtigungen & mehr'),
          _settingSwitch(
            'Benachrichtigungen',
            'Push-Benachrichtigungen aktivieren',
            Icons.notifications_rounded,
            appProvider.notificationsEnabled,
            appProvider.setNotifications,
          ),
          _settingSwitch(
            'Preisalarme',
            'Werde benachrichtigt wenn Preise sinken',
            Icons.price_change_rounded,
            appProvider.priceAlertsEnabled,
            appProvider.setPriceAlerts,
          ),
          _settingSwitch(
            'Autobahn vermeiden',
            'Routenplaner nutzt Landstraßen statt Autobahn',
            Icons.no_crash_rounded,
            appProvider.avoidHighway,
            appProvider.setAvoidHighway,
          ),
          _settingSwitch(
            'Alle Preise anzeigen',
            'Diesel, E5 und E10 immer gleichzeitig anzeigen',
            Icons.summarize_rounded,
            context.watch<FuelProvider>().showAllPrices,
            (val) =>
                context.read<FuelProvider>().batchUpdate(showAllPrices: val),
          ),
          if (appProvider.priceAlertsEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Alarmschwelle',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${appProvider.priceAlertThreshold.toStringAsFixed(2)} €',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: appProvider.priceAlertThreshold,
                      min: 1.40,
                      max: 2.20,
                      divisions: 80,
                      onChanged: appProvider.setPriceAlertThreshold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kraftstoff-Sorte für Alarme',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _fuelSmallChip(context, appProvider, 'Diesel', 'diesel'),
                      const SizedBox(width: 8),
                      _fuelSmallChip(context, appProvider, 'E5', 'e5'),
                      const SizedBox(width: 8),
                      _fuelSmallChip(context, appProvider, 'E10', 'e10'),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          _sectionTitle('Konto'),

          if (user != null)
            _settingItem(
              'Abmelden',
              'Vom Konto ausloggen',
              Icons.logout_rounded,
              color: AppColors.expensive,
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
            ),

          _settingItem(
            'Konto löschen',
            'Account und Daten löschen',
            Icons.delete_outline_rounded,
            color: AppColors.expensive,
            onTap:
                user == null ? null : () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Rechtliches & Kontakt'),

          _settingItem(
            'Impressum',
            'Ammari Developer · Bayreuth',
            Icons.info_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ImpressumScreen(),
              ),
            ),
          ),
          _settingItem(
            'Datenschutzerklärung (DSGVO)',
            'Datenschutz & Ihre Rechte',
            Icons.shield_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DatenschutzScreen(),
              ),
            ),
          ),

          _settingItem(
            'Datenquelle & Preis-Hinweise',
            'Tankerkönig API, Lizenzen & Haftung',
            Icons.source_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DatenquelleScreen(),
              ),
            ),
          ),
          _settingItem(
            'FAQ',
            'Häufig gestellte Fragen',
            Icons.help_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            ),
          ),
          _settingItem(
            'Kontakt & Support',
            'Nachricht senden oder an moussahimammari1234@gmail.com',
            Icons.mail_outline_rounded,
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),

          const SizedBox(height: 24),
          const _AppVersionFooter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
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

  Widget _settingItem(
    String title,
    String subtitle,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color ?? AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _fuelSmallChip(
      BuildContext context, AppProvider provider, String label, String type) {
    final isSelected = provider.priceAlertFuelType == type;
    return GestureDetector(
      onTap: () => provider.setPriceAlertFuelType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';
        return Center(
          child: Column(
            children: [
              Text(
                'ZapfNavi: Günstig Tanken',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Version $version • Build $buildNumber',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
