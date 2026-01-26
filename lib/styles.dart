import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Large - Roboto Flex
  static TextStyle large = GoogleFonts.roboto(
    fontSize: 46,
    height: 50 / 46, // Line height as ratio
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );

  // SubMedium - Roboto Flex
  static TextStyle subMedium = GoogleFonts.roboto(
    fontSize: 22,
    height: 28 / 22, // Line height as ratio
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );

  // Button/CTA - Roboto Mono
  static TextStyle button = GoogleFonts.robotoMono(
    fontSize: 16, // Standard button size
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // Additional helper styles
  static TextStyle body = GoogleFonts.roboto(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
}

class AppColors {
  static const Color primary = Color(0xFF1E88E5); // Modern blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFf2f2f7);
  static const Color background = Color(0xFFFAFAFA);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}