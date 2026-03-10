import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Palette — User Specified ──────────────────────────────────────────────
  static const Color primary = Color(0xFFFF7F11); // Vibrant Orange
  static const Color primaryDark = Color(0xFFD96A0E);
  static const Color primarySoft = Color(0xFF2D1B0D);
  static const Color primaryGlow = Color(0x40FF7F11);

  static const Color secondary = Color(0xFFACBFA4); // Sage Green
  static const Color secondaryDark = Color(0xFF8E9F86);
  static const Color secondarySoft = Color(0xFF1E241C);

  // ── Background: #2C2C2C as specified by user ──────────────────────────────
  static const Color background = Color(0xFF2C2C2C); // Standard Dark Background
  static const Color backgroundLight = Color(0xFF333333);

  static const Color dark = Color(0xFF1A1A1A);
  static const Color darkLight = Color(0xFF222222);
  static const Color darkMuted = Color(0xFF616161);

  // ── UI Functional Colors ──────────────────────────────────────────────────
  static const Color surface = Color(0xFF242424); // Slightly lighter than bg
  static const Color surfaceVariant = Color(0xFF3A3A3A);
  static const Color cardBg = Color(0xFF303030); // Card sits above bg

  static const Color textPrimary = Color(0xFFF5F5F5); // Off-White
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textMuted =
      Color(0xFF9E9E9E); // Slightly lighter for readability
  static const Color buttonText = Color(0xFFFFFFFF);

  // ── Price Status ──────────────────────────────────────────────────────────
  static const Color cheap = Color(0xFF4CAF50); // Vibrant Green
  static const Color medium = Color(0xFFFF7F11); // Orange
  static const Color expensive = Color(0xFFF44336); // Red

  // ── Specific Banner Colors ────────────────────────────────────────────────
  static const Color topDealBg = Color(0xFF2E7D32); // Dark Green for Banner
  static const Color topDealGlow = Color(0xFF43A047);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF424242); // Visible border on #2C2C2C bg
  static const Color divider = Color(0xFF383838);
  static const Color danger = Color(0xFFF44336);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.expensive,
        onPrimary: AppColors.buttonText,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.backgroundLight,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0),
          displayMedium: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
          displaySmall: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineSmall: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          bodySmall: TextStyle(
              color: AppColors.textMuted, fontWeight: FontWeight.w500),
          labelLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          minimumSize: const Size(0, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
            color: AppColors.textMuted, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.surface
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.divider, thickness: 1.5, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.outfit(
            color: AppColors.buttonText,
            fontSize: 14,
            fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
