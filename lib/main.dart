import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

import 'app/theme.dart';
import 'providers/app_providers.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/main_fuel_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'screens/legal/legal_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/support/contact_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/price_alarm/price_alarm_screen.dart';
import 'screens/route/route_planner_screen.dart';
import 'screens/faq/faq_screen.dart';

import 'services/price_alarm_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔔 Native: Background Task Executed: $task');
    await PriceAlarmService().checkAndNotify();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase/Crashlytics Init Error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Initialize Supabase FIRST (needed for remote config / auth)
  try {
    await Supabase.initialize(
      url: 'https://tlhfodjkihrrbcnnsbdh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRsaGZvZGpraWhycmJjbm5zYmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2MTcwNjAsImV4cCI6MjA4NzE5MzA2MH0.sk9rwmsyCMNOEllHLyaUac38SBPfq0OJ7FM-AZhR010',
    ).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Supabase init timeout'),
    );
  } catch (e) {
    debugPrint('Supabase Init Error (non-fatal): $e');
  }

  // 2. Notification service (no ads dependency)
  await NotificationService().init();

  // 5. Background Tasks (WorkManager for price alarm)
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    "1",
    "backgroundPriceCheck",
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const SpritzpreisApp());
}

class SpritzpreisApp extends StatelessWidget {
  const SpritzpreisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => FuelProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: MaterialApp(
        title: 'ZapfNavi: Günstig Tanken',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/home': (_) => const MainFuelScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/premium': (_) => const PremiumScreen(),
          '/legal': (_) => const LegalScreen(),
          '/impressum': (_) => const ImpressumScreen(),
          '/datenschutz': (_) => const DatenschutzScreen(),
          '/datenquelle': (_) => const DatenquelleScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/support': (_) => const ContactScreen(),
          '/favorites': (_) => const FavoritesScreen(),
          '/price-alarm': (_) => const PriceAlarmScreen(),
          '/route-planner': (_) => const RoutePlannerScreen(),
          '/faq': (_) => const FaqScreen(),
        },
      ),
    );
  }
}
