import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches and caches app configuration (like API keys) from Supabase.
/// The API key is stored securely in Supabase with Row Level Security —
/// only authenticated users can read it.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // In-memory cache — key fetched once per app session
  final Map<String, String> _cache = {};

  /// Returns the Tankerkönig API key.
  /// Loads from Supabase on first call, then returns cached value.
  Future<String?> getTankerkoenigApiKey() async {
    return _getConfig('tankerkoenig_api_key');
  }

  Future<String?> _getConfig(String key) async {
    // Return cached value if available
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final value = response['value'] as String;
        _cache[key] = value;
        debugPrint('🔑 ConfigService: Loaded "$key" from Supabase.');
        return value;
      } else {
        debugPrint('🔑 ConfigService: Key "$key" not found in Supabase.');
        return null;
      }
    } catch (e) {
      debugPrint('🔑 ConfigService Error loading "$key": $e');
      return null;
    }
  }

  /// Clears the local cache (e.g. after re-login)
  void clearCache() => _cache.clear();
}
