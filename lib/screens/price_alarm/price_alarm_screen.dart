import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/alarm_config.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../services/price_alarm_service.dart';

class PriceAlarmScreen extends StatefulWidget {
  const PriceAlarmScreen({super.key});

  @override
  State<PriceAlarmScreen> createState() => _PriceAlarmScreenState();
}

class _PriceAlarmScreenState extends State<PriceAlarmScreen> {
  late TextEditingController _priceController;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    final threshold = context.read<AppProvider>().priceAlertThreshold;
    _priceController =
        TextEditingController(text: threshold.toStringAsFixed(3));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _applyManualInput(AppProvider appProvider) {
    final raw = _priceController.text.replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value < 1.20 || value > 2.50) {
      setState(() =>
          _inputError = 'Bitte Preis zwischen 1,20 € und 2,50 € eingeben');
      return;
    }
    setState(() => _inputError = null);
    appProvider.setPriceAlertThreshold(value);
    _priceController.text = value.toStringAsFixed(3);
    FocusScope.of(context).unfocus();
    PriceAlarmService().checkAndNotify();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Alarmschwelle auf ${value.toStringAsFixed(3)} € gesetzt ✅'),
        backgroundColor: AppColors.cheap,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    int initHour,
    int initMinute,
    void Function(int h, int m) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initHour, minute: initMinute),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final alarm = appProvider.alarmConfig;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Preisalarm',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preisalarm',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                            'Werde sofort benachrichtigt, wenn der Preis unter deine Schwelle fällt.',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Enable Toggle ──────────────────────────────────────────────
            _card(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.price_change_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preisalarm aktivieren',
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text('Benachrichtigung wenn Preis sinkt',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarm.enabled,
                    onChanged: (val) async {
                      if (val) {
                        await NotificationService().requestPermissions();
                      }
                      appProvider.setPriceAlerts(val);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            if (alarm.enabled) ...[
              const SizedBox(height: 16),

              // ── Alarmschwelle ─────────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 10),
                        Text('Alarmschwelle',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${alarm.thresholdPrice.toStringAsFixed(3)} €',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Alarm wenn Preis unter diesen Wert fällt',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 14),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primaryGlow,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: alarm.thresholdPrice.clamp(1.20, 2.50),
                        min: 1.20,
                        max: 2.50,
                        divisions: 130,
                        onChanged: (v) {
                          appProvider.setPriceAlertThreshold(v);
                          _priceController.text = v.toStringAsFixed(3);
                          setState(() => _inputError = null);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1,20 €',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: AppColors.textMuted)),
                        Text('2,50 €',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 12),
                    Text('Oder Preis manuell eingeben:',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]')),
                            ],
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: 'z.B. 1.739',
                              hintStyle: GoogleFonts.outfit(
                                  color: AppColors.textMuted, fontSize: 14),
                              suffixText: '€',
                              suffixStyle: GoogleFonts.outfit(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600),
                              filled: true,
                              fillColor: AppColors.surface,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                              errorText: _inputError,
                              errorStyle: GoogleFonts.outfit(
                                  fontSize: 11, color: AppColors.expensive),
                            ),
                            onChanged: (_) =>
                                setState(() => _inputError = null),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => _applyManualInput(appProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: Text('OK',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Kraftstoffsorte ───────────────────────────────────────────
              _sectionLabel('Kraftstoffsorte'),
              _card(
                child: Row(
                  children: ['e5', 'e10', 'diesel'].map((ft) {
                    final selected = alarm.fuelType == ft;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => appProvider.setPriceAlertFuelType(ft),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Text(
                            ft == 'e5'
                                ? 'Super E5'
                                : ft == 'e10'
                                    ? 'Super E10'
                                    : 'Diesel',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ── P2: Bereich (Scope) ────────────────────────────────────────
              _sectionLabel('Bereich'),
              _card(
                child: Column(
                  children: [
                    _scopeOption(
                      icon: Icons.location_on_rounded,
                      title: 'Aktuelle Suchregion',
                      subtitle:
                          'Tankstellen um deinen letzten bekannten Standort',
                      selected: alarm.scope == AlarmScope.region,
                      onTap: () => appProvider.setAlarmScope(AlarmScope.region),
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _scopeOption(
                      icon: Icons.star_rounded,
                      title: 'Nur Favoriten',
                      subtitle: 'Alarm nur für deine gespeicherten Tankstellen',
                      selected: alarm.scope == AlarmScope.favorites,
                      onTap: () =>
                          appProvider.setAlarmScope(AlarmScope.favorites),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── P2: Erweiterte Optionen ────────────────────────────────────
              _sectionLabel('Erweiterte Optionen'),
              _card(
                child: Column(
                  children: [
                    // Only Open
                    _toggleRow(
                      icon: Icons.door_front_door_rounded,
                      iconColor: AppColors.cheap,
                      title: 'Nur wenn geöffnet',
                      subtitle:
                          'Keine Benachrichtigung für geschlossene Stationen',
                      value: alarm.onlyOpen,
                      onChanged: (v) => appProvider.setAlarmOnlyOpen(v),
                    ),
                    const Divider(color: AppColors.divider, height: 20),

                    // Sound
                    _toggleRow(
                      icon: Icons.volume_up_rounded,
                      iconColor: AppColors.medium,
                      title: 'Sound-Benachrichtigung',
                      subtitle: 'Alarmton wenn Preis fällt',
                      value: alarm.soundEnabled,
                      onChanged: (v) => appProvider.setAlarmSound(v),
                    ),
                    const Divider(color: AppColors.divider, height: 20),

                    // Cooldown
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timer_outlined,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mindestabstand',
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              Text(
                                  'Höchstens alle ${alarm.cooldownMinutes} Min. benachrichtigen',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primaryGlow,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: alarm.cooldownMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '${alarm.cooldownMinutes} Min.',
                        onChanged: (v) =>
                            appProvider.setAlarmCooldown(v.round()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5 Min.',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: AppColors.textMuted)),
                        Text('${alarm.cooldownMinutes} Min.',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        Text('2 Std.',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── P2: Ruhezeiten ─────────────────────────────────────────────
              _sectionLabel('Ruhezeiten'),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _toggleRow(
                      icon: Icons.bedtime_rounded,
                      iconColor: const Color(0xFF7C83FD),
                      title: 'Ruhezeiten aktivieren',
                      subtitle: 'Keine Benachrichtigungen in der Nacht',
                      value: alarm.quietHoursEnabled,
                      onChanged: (v) => appProvider.setAlarmQuietEnabled(v),
                    ),
                    if (alarm.quietHoursEnabled) ...[
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _timeButton(
                              label: 'Beginn',
                              time: _padTime(
                                  alarm.quietStartHour, alarm.quietStartMinute),
                              onTap: () => _pickTime(
                                context,
                                alarm.quietStartHour,
                                alarm.quietStartMinute,
                                (h, m) => appProvider.setAlarmQuietStart(h, m),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('bis',
                                style: GoogleFonts.outfit(
                                    color: AppColors.textMuted, fontSize: 13)),
                          ),
                          Expanded(
                            child: _timeButton(
                              label: 'Ende',
                              time: _padTime(
                                  alarm.quietEndHour, alarm.quietEndMinute),
                              onTap: () => _pickTime(
                                context,
                                alarm.quietEndHour,
                                alarm.quietEndMinute,
                                (h, m) => appProvider.setAlarmQuietEnd(h, m),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keine Benachrichtigungen zwischen ${_padTime(alarm.quietStartHour, alarm.quietStartMinute)} und ${_padTime(alarm.quietEndHour, alarm.quietEndMinute)} Uhr',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Status Summary ─────────────────────────────────────────────
              _card(
                child: Column(
                  children: [
                    _infoRow(
                        Icons.check_circle_rounded,
                        AppColors.cheap,
                        'Alarm aktiv',
                        'Bei ${alarm.thresholdPrice.toStringAsFixed(3)} €/L — ${alarm.fuelType.toUpperCase()}'),
                    const SizedBox(height: 12),
                    _infoRow(
                        alarm.scope == AlarmScope.favorites
                            ? Icons.star_rounded
                            : Icons.location_on_rounded,
                        AppColors.primary,
                        alarm.scope == AlarmScope.favorites
                            ? 'Nur Favoriten'
                            : 'Aktuelle Suchregion',
                        alarm.scope == AlarmScope.favorites
                            ? 'Alarm gilt für deine Favoritenstationen'
                            : 'Basiert auf letztem Standort — kein Hintergrund-GPS'),
                    const SizedBox(height: 12),
                    _infoRow(
                        Icons.timer_outlined,
                        AppColors.medium,
                        'Mindestabstand: ${alarm.cooldownMinutes} Min.',
                        'Verhindert Spam-Benachrichtigungen'),
                    if (alarm.quietHoursEnabled) ...[
                      const SizedBox(height: 12),
                      _infoRow(
                          Icons.bedtime_rounded,
                          const Color(0xFF7C83FD),
                          'Ruhezeiten aktiv',
                          '${_padTime(alarm.quietStartHour, alarm.quietStartMinute)} – ${_padTime(alarm.quietEndHour, alarm.quietEndMinute)} Uhr'),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Preisalarm deaktiviert',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                        'Aktiviere den Schalter oben\num Preisbenachrichtigungen zu erhalten.',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.5),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _padTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _scopeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 2),
              color: selected ? AppColors.primary : Colors.transparent,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.black, size: 12)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary),
      ],
    );
  }

  Widget _timeButton({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(time,
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
