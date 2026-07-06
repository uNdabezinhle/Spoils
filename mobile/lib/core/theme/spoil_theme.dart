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
        backgroundColor: Colors.transparent,
        foregroundColor: SpoilColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SpoilColors.charcoal,
        ),
      ),
      cardTheme: CardTheme(
        color: SpoilColors.surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpoilColors.radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SpoilColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpoilColors.radiusMd)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SpoilColors.gold,
          foregroundColor: SpoilColors.charcoal,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpoilColors.radiusMd)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SpoilColors.teal,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: SpoilColors.teal, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpoilColors.radiusMd)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpoilColors.surfaceMuted,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpoilColors.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpoilColors.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpoilColors.radiusMd),
          borderSide: const BorderSide(color: SpoilColors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpoilColors.radiusMd),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: SpoilColors.charcoalMuted),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: SpoilColors.charcoalSubtle),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SpoilColors.surface,
        selectedColor: SpoilColors.tealTint,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: SpoilColors.tealTint,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? SpoilColors.teal : SpoilColors.charcoalMuted,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? SpoilColors.teal : SpoilColors.charcoalSubtle,
            size: 24,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF3F4F6), thickness: 1),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return TextTheme(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: SpoilColors.charcoal,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: SpoilColors.charcoal,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: SpoilColors.charcoal,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: SpoilColors.charcoal,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: SpoilColors.charcoal,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, color: SpoilColors.charcoal),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: SpoilColors.charcoalMuted),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, color: SpoilColors.charcoalSubtle),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}