import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/spoil_colors.dart';

class SpoilLogo extends StatelessWidget {
  const SpoilLogo({super.key, this.size = 28, this.showTagline = false});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Spoil',
          style: GoogleFonts.playfairDisplay(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: SpoilColors.teal,
            letterSpacing: -0.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Spoil them properly.',
            style: GoogleFonts.inter(
              fontSize: size * 0.42,
              color: SpoilColors.gold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}