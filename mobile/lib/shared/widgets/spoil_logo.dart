import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/brand_constants.dart';
import '../../core/theme/spoil_colors.dart';

class SpoilLogo extends StatelessWidget {
  const SpoilLogo({
    super.key,
    this.size = 28,
    this.showTagline = false,
    this.light = false,
  });

  final double size;
  final bool showTagline;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final nameColor = light ? Colors.white : SpoilColors.teal;
    final taglineColor = light ? SpoilColors.goldLight : SpoilColors.gold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          BrandConstants.appName,
          style: GoogleFonts.fraunces(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: nameColor,
            letterSpacing: -0.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            BrandConstants.tagline,
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.4,
              color: taglineColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}