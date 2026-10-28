import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized text styles for the app
/// All text styles use Google Fonts (Outfit)
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // ============================================================================
  // DISPLAY STYLES (Largest headings)
  // ============================================================================

  /// Display large - 48px
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Display medium - 40px
  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Display small - 32px
  static TextStyle get displaySmall => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // ============================================================================
  // HEADING STYLES
  // ============================================================================

  /// Heading 1 - 28px
  static TextStyle get h1 => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Heading 2 - 24px
  static TextStyle get h2 => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Heading 3 - 20px
  static TextStyle get h3 => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Heading 4 - 18px
  static TextStyle get h4 => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Heading 5 - 16px
  static TextStyle get h5 => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// Heading 6 - 14px
  static TextStyle get h6 => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ============================================================================
  // BODY STYLES
  // ============================================================================

  /// Body large - 18px
  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  /// Body medium (default) - 16px
  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  /// Body small - 14px
  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  // ============================================================================
  // SPECIAL STYLES
  // ============================================================================

  /// Button text - 16px, bold, uppercase
  static TextStyle get button => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );

  /// Button small text - 14px, bold, uppercase
  static TextStyle get buttonSmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );

  /// Label text - 14px, bold, spaced
  static TextStyle get label => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  /// Label small - 12px, bold, spaced
  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  /// Caption - 12px
  static TextStyle get caption => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  /// Overline - 10px, uppercase, spaced
  static TextStyle get overline => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  // ============================================================================
  // PRICE STYLES
  // ============================================================================

  /// Price large - 24px, bold
  static TextStyle get priceLarge =>
      GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold);

  /// Price medium - 20px, bold
  static TextStyle get priceMedium =>
      GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold);

  /// Price small - 18px, bold
  static TextStyle get priceSmall =>
      GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold);

  // ============================================================================
  // LINK STYLES
  // ============================================================================

  /// Link - 16px, underlined
  static TextStyle get link => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
    decoration: TextDecoration.underline,
  );

  /// Link small - 14px, underlined
  static TextStyle get linkSmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
    decoration: TextDecoration.underline,
  );

  // ============================================================================
  // ERROR/SUCCESS STYLES
  // ============================================================================

  /// Error text
  static TextStyle get error => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
  );

  /// Success text
  static TextStyle get success => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
  );

  /// Warning text
  static TextStyle get warning => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.warning,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Get text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}
