import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const teal = Color(0xFF2E7F87);
  static const tealDark = Color(0xFF1F6670);
  static const tealTint = Color(0xFFE3F4F5);
  static const ink = Color(0xFF10202A);
  // 5.6:1 on white, passes WCAG AA for body text.
  static const muted = Color(0xFF5B6B73);
  static const background = Color(0xFFF4FAFA);
  static const aqua = Color(0xFFD9F1F2);
  static const border = Color(0xFFDDE7E7);
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
      primary: AppColors.teal,
      surface: Colors.white,
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
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );
  static TextStyle get title => GoogleFonts.inter(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );
  static TextStyle get section => GoogleFonts.inter(
    fontSize: 18,
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
