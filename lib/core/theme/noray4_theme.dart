import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────

abstract final class Noray4Colors {
  // ── Palette source ───────────────────────────────────────────────────────
  // #10454F  deep teal   → surface containers
  // #506266  mid teal    → outline-variant / borders
  // #818274  warm gray   → on-surface-variant / outline
  // #A3AB78  sage        → secondary text
  // #BDE038  lime        → accent (primary action)

  // Light mode
  static const background = Color(0xFFFAFAF8);
  static const surfaceCard = Color(0xFFF2F2EF);
  static const surfaceMuted = Color(0xFFE8E8E4);
  static const border = Color(0xFFD4D4D0);
  static const textPrimary = Color(0xFF111110);
  static const textSecondary = Color(0xFF506266); // mid teal
  static const textMuted = Color(0xFF818274);     // warm gray

  // Dark mode — backgrounds (deep teal–tinted dark)
  static const darkBackground = Color(0xFF0C1C20);
  static const darkSurface = Color(0xFF0C1C20);
  static const darkSurfaceContainerLowest = Color(0xFF091419);
  static const darkSurfaceContainerLow = Color(0xFF112630);
  static const darkSurfaceContainer = Color(0xFF1A3038);
  static const darkSurfaceContainerHigh = Color(0xFF223840);
  static const darkSurfaceContainerHighest = Color(0xFF2C4550);
  static const darkSurfaceBright = Color(0xFF354F58);

  // Dark mode — text
  static const darkPrimary = Color(0xFFFFFFFF);
  static const darkSecondary = Color(0xFFA3AB78);      // sage
  static const darkOnSurface = Color(0xFFD8EAE2);      // teal-tinted white
  static const darkOnSurfaceVariant = Color(0xFF818274); // warm gray

  // Dark mode — borders
  static const darkOutlineVariant = Color(0xFF506266);  // mid teal
  static const darkOutline = Color(0xFF818274);         // warm gray

  // Dark mode — accent
  static const darkAccent = Color(0xFFBDE038);          // lime
  static const darkAccentDim = Color(0x33BDE038);       // lime 20%
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
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Noray4Colors.darkAccent,
          onPrimary: Color(0xFF0C1C20),
          secondary: Noray4Colors.darkSecondary,
          onSecondary: Noray4Colors.darkBackground,
          surface: Noray4Colors.darkBackground,
          onSurface: Noray4Colors.darkOnSurface,
          error: Color(0xFFFF453A),
          onError: Colors.white,
          surfaceContainerLowest: Noray4Colors.darkSurfaceContainerLowest,
          surfaceContainerLow: Noray4Colors.darkSurfaceContainerLow,
          surfaceContainer: Noray4Colors.darkSurfaceContainer,
          surfaceContainerHigh: Noray4Colors.darkSurfaceContainerHigh,
          surfaceContainerHighest: Noray4Colors.darkSurfaceContainerHighest,
          outline: Noray4Colors.darkOutline,
          outlineVariant: Noray4Colors.darkOutlineVariant,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyMedium: Noray4TextStyles.body.copyWith(color: Noray4Colors.darkOnSurface),
          bodySmall: Noray4TextStyles.bodySmall.copyWith(color: Noray4Colors.darkOnSurface),
        ),
        dividerColor: Colors.transparent,
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      );
}
