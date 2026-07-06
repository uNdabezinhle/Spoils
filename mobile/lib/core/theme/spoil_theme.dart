import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spoil_colors.dart';

abstract final class SpoilTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SpoilColors.teal,
        primary: SpoilColors.teal,
        secondary: SpoilColors.gold,
        surface: SpoilColors.cream,
        onPrimary: Colors.white,
        onSecondary: SpoilColors.charcoal,
        onSurface: SpoilColors.charcoal,
      ),
      scaffoldBackgroundColor: SpoilColors.cream,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: SpoilColors.cream,
        foregroundColor: SpoilColors.charcoal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: SpoilColors.teal,
        ),
      ),
      cardTheme: CardTheme(
        color: SpoilColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpoilColors.blush.withOpacity(0.6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SpoilColors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SpoilColors.teal,
          side: const BorderSide(color: SpoilColors.teal),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SpoilColors.blush),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SpoilColors.blush),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpoilColors.teal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: SpoilColors.blush,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? SpoilColors.teal : SpoilColors.charcoal.withOpacity(0.6),
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? SpoilColors.teal : SpoilColors.charcoal.withOpacity(0.5),
            size: 24,
          );
        }),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: SpoilColors.charcoal,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: SpoilColors.charcoal,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: SpoilColors.teal,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: SpoilColors.charcoal,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: SpoilColors.charcoal,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: SpoilColors.charcoal),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: SpoilColors.charcoal.withOpacity(0.85)),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: SpoilColors.charcoal.withOpacity(0.65)),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}