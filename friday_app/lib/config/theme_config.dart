import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the complete design system for FRIDAY Lite.
///
/// Palette — Space Obsidian dark theme with Electric Teal accents.
/// Typography — Outfit (headings) + Inter (body).
class ThemeConfig {
  ThemeConfig._();

  // ---------------------------------------------------------------------------
  // Color Palette
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFF090B10);       // Deep space black
  static const Color surface = Color(0xFF111827);          // Card surface
  static const Color surfaceElevated = Color(0xFF1C2333);  // Elevated card

  static const Color primary = Color(0xFF00E5FF);          // Electric cyan
  static const Color primaryDim = Color(0xFF0097A7);       // Muted cyan
  static const Color primaryGlow = Color(0x3300E5FF);      // Glow layer

  static const Color accent = Color(0xFF7C3AED);           // Deep violet
  static const Color accentGlow = Color(0x337C3AED);

  // Status colours
  static const Color statusOff = Color(0xFFEF4444);        // Red
  static const Color statusListening = Color(0xFF22C55E);  // Green
  static const Color statusProcessing = Color(0xFFF59E0B); // Amber
  static const Color statusSpeaking = Color(0xFF3B82F6);   // Blue

  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  static const Color border = Color(0xFF1E293B);
  static const Color borderSubtle = Color(0xFF0F172A);

  // Orb gradient colours by mode
  static const List<Color> orbOff = [
    Color(0xFF1A1A2E),
    Color(0xFF3D0000),
    Color(0xFF1A1A2E),
  ];
  static const List<Color> orbListening = [
    Color(0xFF003340),
    Color(0xFF00E5FF),
    Color(0xFF003340),
  ];
  static const List<Color> orbProcessing = [
    Color(0xFF2D1B00),
    Color(0xFFF59E0B),
    Color(0xFF2D1B00),
  ];
  static const List<Color> orbSpeaking = [
    Color(0xFF1A0040),
    Color(0xFF7C3AED),
    Color(0xFF001440),
  ];

  // ---------------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------------

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 45,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 2.0,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.5,
        ),
      );

  // ---------------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------------

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: primary,
          onPrimary: Color(0xFF001820),
          secondary: accent,
          onSecondary: Color(0xFF100025),
          surface: surface,
          onSurface: textPrimary,
          error: Color(0xFFEF4444),
          onError: Color(0xFF1A0000),
        ),
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: textSecondary),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          titleTextStyle: textTheme.titleLarge,
          iconTheme: const IconThemeData(color: textSecondary),
          surfaceTintColor: Colors.transparent,
        ),
      );
}
