import 'package:flutter/material.dart';

import 'spoil_colors.dart';

abstract final class SpoilDecorations {
  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? SpoilColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SpoilColors.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: SpoilColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration navBar() => BoxDecoration(
        color: SpoilColors.surface,
        borderRadius: BorderRadius.circular(SpoilColors.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      );

  static const Gradient heroGradient = LinearGradient(
    colors: [SpoilColors.teal, SpoilColors.tealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient splashGradient = LinearGradient(
    colors: [SpoilColors.teal, SpoilColors.tealDark, Color(0xFF0D4F4A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient profileHeaderGradient = LinearGradient(
    colors: [SpoilColors.teal, SpoilColors.tealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}