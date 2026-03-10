import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../screens/legal/legal_screen.dart';

/// SplashScreen — transparent bridge between the native Android splash and app content.
///
/// Fix E (double splash): This screen renders NOTHING visible (just the dark
/// background that matches the native LaunchTheme). The Android system splash
/// (from windowBackground drawable) is the ONLY perceived splash.
/// We perform async init here and navigate as fast as possible.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // ── GDPR Consent (only on first launch) ──────────────────────────────────
    await GdprConsentDialog.showIfNeeded(context);
    if (!mounted) return;

    // Read onboarding state directly from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;

    // Keep provider in sync
    context.read<AppProvider>().syncFromPrefs(hasOnboarded);

    // Check Auth State
    final isLoggedIn = AuthService().isLoggedIn;

    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (!hasOnboarded) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    // Render only the background — blends seamlessly with native splash.
    // No logo, no text, no animation — single perceived splash experience.
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(),
    );
  }
}
