/// AlarmConfig — the complete Preisalarm configuration model.
/// Persisted via SharedPreferences. Provides migration defaults.
class AlarmConfig {
  final bool enabled;
  final String fuelType; // 'e5', 'e10', 'diesel'
  final double thresholdPrice;
  final AlarmScope scope; // favorites or region
  final bool onlyOpen; // notify only if station is currently open
  final int
      cooldownMinutes; // minimum minutes between notifications (per alarm)
  final bool quietHoursEnabled;
  final int quietStartHour; // 0–23
  final int quietStartMinute; // 0–59
  final int quietEndHour;
  final int quietEndMinute;
  final bool soundEnabled;

  const AlarmConfig({
    this.enabled = false,
    this.fuelType = 'e5',
    this.thresholdPrice = 1.70,
    this.scope = AlarmScope.region,
    this.onlyOpen = true,
    this.cooldownMinutes = 30,
    this.quietHoursEnabled = false,
    this.quietStartHour = 22,
    this.quietStartMinute = 0,
    this.quietEndHour = 7,
    this.quietEndMinute = 0,
    this.soundEnabled = true,
  });

  AlarmConfig copyWith({
    bool? enabled,
    String? fuelType,
    double? thresholdPrice,
    AlarmScope? scope,
    bool? onlyOpen,
    int? cooldownMinutes,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietStartMinute,
    int? quietEndHour,
    int? quietEndMinute,
    bool? soundEnabled,
  }) {
    return AlarmConfig(
      enabled: enabled ?? this.enabled,
      fuelType: fuelType ?? this.fuelType,
      thresholdPrice: thresholdPrice ?? this.thresholdPrice,
      scope: scope ?? this.scope,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietStartMinute: quietStartMinute ?? this.quietStartMinute,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      quietEndMinute: quietEndMinute ?? this.quietEndMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  /// Key names for SharedPreferences — centralized to avoid typos.
  static const String kEnabled = 'price_alerts';
  static const String kFuelType = 'alert_fuel_type';
  static const String kThreshold = 'alert_threshold';
  static const String kScope = 'alarm_scope';
  static const String kOnlyOpen = 'alarm_only_open';
  static const String kCooldown = 'alarm_cooldown_min';
  static const String kQuietEnabled = 'alarm_quiet_enabled';
  static const String kQuietStartHour = 'alarm_quiet_start_h';
  static const String kQuietStartMin = 'alarm_quiet_start_m';
  static const String kQuietEndHour = 'alarm_quiet_end_h';
  static const String kQuietEndMin = 'alarm_quiet_end_m';
  static const String kSound = 'alarm_sound';
  static const String kLastNotified = 'alarm_last_notified_ms';
}

enum AlarmScope {
  region, // current / last search region (no background GPS)
  favorites, // only user-saved favorites
}
