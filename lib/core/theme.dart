import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bgMain = Color(0xFFF4F7FC);
  static final Color surfaceCard = const Color(0xFFFFFFFF).withValues(alpha: 0.55);
  static final Color surfaceExpanded = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
  static const Color line = Color(0xFFD1D5DB);
  static const Color textPrimary = Color(0xFF1A1B20);
  static const Color textSecondary = Color(0xFF81838A);
  static const Color actionPrimary = Color(0xFF2A5CFF);

  // Semantic
  static const Color successSoft = Color(0xFFBFE8D6);
  static const Color successBold = Color(0xFF25875A);
  static const Color dangerSoft = Color(0xFFF9C3E6);
  static const Color dangerBold = Color(0xFF8D356B);
}

class AppTypography {
  static TextStyle get heading => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyPrimary => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle get captionSecondary => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}

class AppShapes {
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;

  static final List<BoxShadow> shadowSoftSm = [
    BoxShadow(
      color: const Color(0xFF1A1B20).withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static final List<BoxShadow> shadowSoftMd = [
    BoxShadow(
      color: const Color(0xFF1A1B20).withValues(alpha: 0.1),
      offset: const Offset(0, 18),
      blurRadius: 50,
    ),
  ];
}
