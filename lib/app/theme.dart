import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  /// Dark theme across the app; follows the globe's 🌙 / ☀️ switch.
  static bool dark = false;

  static const teal = Color(0xFF2E7F87);
  static const tealDark = Color(0xFF1F6670);
  static Color get tealTint =>
      dark ? const Color(0xFF173A3F) : const Color(0xFFE3F4F5);
  static Color get ink =>
      dark ? const Color(0xFFE8F2F1) : const Color(0xFF0F1B3D);
  // 5.6:1 on white (light) and on the dark surface, passes WCAG AA.
  static Color get muted =>
      dark ? const Color(0xFF9DB2B3) : const Color(0xFF5E6B80);
  static Color get background => dark ? const Color(0xFF0B1A1F) : Colors.white;
  static Color get surface => dark ? const Color(0xFF15282E) : Colors.white;
  static Color get aqua =>
      dark ? const Color(0xFF12363B) : const Color(0xFFD9F1F2);
  static Color get border =>
      dark ? const Color(0xFF26404A) : const Color(0xFFDDE7E7);
  static const online = Color(0xFF1E8F55);
  static const star = Color(0xFFD99A00);
}

abstract final class AppRadius {
  static const button = 14.0;
  static const card = 18.0;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: AppColors.dark ? Brightness.dark : Brightness.light,
      primary: AppColors.teal,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    fontFamily: GoogleFonts.inter().fontFamily,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.muted,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Shared text styles, so screens keep one clear hierarchy.
abstract final class AppText {
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );
  static TextStyle get title => GoogleFonts.inter(
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );
  static TextStyle get section => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static TextStyle get body =>
      GoogleFonts.inter(fontSize: 15, height: 1.4, color: AppColors.muted);
  static TextStyle get small =>
      GoogleFonts.inter(fontSize: 13, height: 1.3, color: AppColors.muted);
}
