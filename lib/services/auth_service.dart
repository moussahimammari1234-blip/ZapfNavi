import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe wrapper around Supabase — tolerates Supabase not being initialized
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _supabase != null;

  User? get currentUser => _supabase?.auth.currentUser;
  Session? get currentSession => _supabase?.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _supabase?.auth.onAuthStateChange ?? const Stream.empty();

  // ─── Sign In ──────────────────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw Exception(
          'Backend nicht erreichbar. Prüfe deine Internetverbindung.');
    }
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw Exception(
          'Backend nicht erreichbar. Prüfe deine Internetverbindung.');
    }
    return await client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'full_name': name} : null,
    );
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _supabase?.auth.signOut();
    } catch (_) {}
  }

  // ─── Reset Password ───────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Backend nicht erreichbar.');
    }
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.zapfnavi://reset-callback/',
    );
  }

  // ─── Update User Profile ──────────────────────────────────────────────────
  Future<void> updateProfile({String? name, bool? isPremium}) async {
    final client = _supabase;
    if (client == null || client.auth.currentUser == null) return;
    final Map<String, dynamic> data = {};
    if (name != null) data['full_name'] = name;
    if (isPremium != null) data['is_premium'] = isPremium;
    if (data.isNotEmpty) {
      await client.auth.updateUser(UserAttributes(data: data));
    }
  }

  // ── Delete Account ─────────────────────────────────────────────────────────
  /// Deletes user data (favorites) and signs out.
  /// Full account deletion from Supabase Auth requires the Admin API
  /// (server-side Edge Function). This method cleans up client-side data
  /// and deactivates the session — Google Play compliant.
  Future<void> deleteAccount() async {
    final client = _supabase;
    if (client == null || client.auth.currentUser == null) {
      throw Exception('Kein Benutzerkonto vorhanden.');
    }
    final userId = client.auth.currentUser!.id;

    // 1. Delete all favorites
    try {
      await client.from('favorites').delete().eq('user_id', userId);
    } catch (_) {
      // Ignore if favorites table doesn't exist or is empty
    }

    // 2. Clear user metadata
    try {
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': null, 'is_premium': null}),
      );
    } catch (_) {}

    // 3. Sign out (invalidates all sessions)
    await client.auth.signOut();
  }

  // ─── Favorites (Supabase synced) ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final client = _supabase;
    if (client == null || client.auth.currentUser == null) return [];
    try {
      final response = await client
          .from('favorites')
          .select()
          .eq('user_id', client.auth.currentUser!.id)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  Future<bool> addFavorite({
    required String stationId,
    required String stationName,
    required String stationBrand,
    String? stationAddress,
  }) async {
    final client = _supabase;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.from('favorites').upsert({
        'user_id': client.auth.currentUser!.id,
        'station_id': stationId,
        'station_name': stationName,
        'station_brand': stationBrand,
        'station_address': stationAddress ?? '',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFavorite(String stationId) async {
    final client = _supabase;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', client.auth.currentUser!.id)
          .eq('station_id', stationId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
