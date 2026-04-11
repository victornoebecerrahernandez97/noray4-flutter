import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────

abstract final class Noray4Colors {
  // Light mode
  static const background = Color(0xFFFAFAF8);
  static const surfaceCard = Color(0xFFF2F2EF);
  static const surfaceMuted = Color(0xFFE8E8E4);
  static const border = Color(0xFFD4D4D0);
  static const textPrimary = Color(0xFF111110);
  static const textSecondary = Color(0xFF6B6B68);
  static const textMuted = Color(0xFFA8A8A4);

  // Dark mode
  static const darkBackground = Color(0xFF131312);
  static const darkSurface = Color(0xFF131312);
  static const darkSurfaceContainerLowest = Color(0xFF0E0E0D);
  static const darkSurfaceContainerLow = Color(0xFF1C1C1A);
  static const darkSurfaceContainer = Color(0xFF20201E);
  static const darkSurfaceContainerHigh = Color(0xFF2A2A29);
  static const darkSurfaceContainerHighest = Color(0xFF353533);
  static const darkSurfaceBright = Color(0xFF3A3938);
  static const darkPrimary = Color(0xFFFFFFFF);
  static const darkSecondary = Color(0xFFC7C7C2);
  static const darkOnSurface = Color(0xFFE5E2E0);
  static const darkOnSurfaceVariant = Color(0xFFC6C6C6);
  static const darkOutlineVariant = Color(0xFF474747);
  static const darkOutline = Color(0xFF919191);
}

// ─── Text Styles ─────────────────────────────────────────────────────────────

abstract final class Noray4TextStyles {
  static TextStyle get wordmark => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05 * 24,
        color: Noray4Colors.textPrimary,
      );

  static TextStyle get headlineL => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 32,
      );

  static TextStyle get headlineM => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 20,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.01 * 12,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 10,
      );
}

// ─── Spacing ─────────────────────────────────────────────────────────────────

abstract final class Noray4Spacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s4 = 16;
  static const double s6 = 24;
  static const double s8 = 32;
}

// ─── Radius ──────────────────────────────────────────────────────────────────

abstract final class Noray4Radius {
  static const primary = BorderRadius.all(Radius.circular(12));
  static const secondary = BorderRadius.all(Radius.circular(8));
  static const pill = BorderRadius.all(Radius.circular(999));
}

// ─── ThemeData ───────────────────────────────────────────────────────────────

abstract final class Noray4Theme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Noray4Colors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Noray4Colors.textPrimary,
          brightness: Brightness.light,
          surface: Noray4Colors.background,
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          bodyMedium: Noray4TextStyles.body,
          bodySmall: Noray4TextStyles.bodySmall,
        ),
        dividerColor: Colors.transparent,
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Noray4Colors.darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Noray4Colors.darkPrimary,
          brightness: Brightness.dark,
          surface: Noray4Colors.darkBackground,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyMedium: Noray4TextStyles.body.copyWith(color: Noray4Colors.darkOnSurface),
          bodySmall: Noray4TextStyles.bodySmall.copyWith(color: Noray4Colors.darkOnSurface),
        ),
        dividerColor: Colors.transparent,
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      );
}
