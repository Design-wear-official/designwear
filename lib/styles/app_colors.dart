import 'package:flutter/material.dart';

/// Centralized color palette for the DesignWear app
/// This is the single source of truth for all colors used in the app
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // BRAND COLORS
  // ============================================================================

  /// Primary brand color - Deep Black
  static const Color black = Color(0xFF1A1A1A);

  /// Secondary brand color - Muted Gold
  static const Color gold = Color(0xFFD4AF37);

  /// Accent color - Deep Purple (for special features like Virtual Try-On)
  static const Color purple = Colors.deepPurple;

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================

  /// Pure white
  static const Color white = Colors.white;

  /// Background color for the app
  static const Color background = Colors.white;

  /// Surface color for cards and elevated elements
  static const Color surface = Colors.white;

  /// Light gray background (for subtle backgrounds)
  static const Color backgroundLight = Color(0xFFFAFAFA);

  /// Gray shades
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success color (green)
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF388E3C);

  /// Error color (red)
  static const Color error = Color(0xFFB00020);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFC62828);

  /// Warning color (orange)
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFF57C00);

  /// Info color (blue)
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF1976D2);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text color (dark)
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Secondary text color (medium gray)
  static const Color textSecondary = Color(0xFF757575);

  /// Disabled text color (light gray)
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// Hint text color
  static const Color textHint = Color(0xFF9E9E9E);

  /// Text on dark backgrounds
  static const Color textOnDark = Colors.white;

  /// Text on gold/accent backgrounds
  static const Color textOnGold = Color(0xFF1A1A1A);

  // ============================================================================
  // BORDER COLORS
  // ============================================================================

  /// Default border color
  static const Color border = Color(0xFFE0E0E0);

  /// Light border color
  static const Color borderLight = Color(0xFFF5F5F5);

  /// Dark border color
  static const Color borderDark = Color(0xFFBDBDBD);

  /// Focus/Active border color
  static const Color borderFocus = gold;

  // ============================================================================
  // SPECIAL COLORS
  // ============================================================================

  /// Badge background color
  static const Color badgeBackground = gold;

  /// Badge text color
  static const Color badgeText = white;

  /// Divider color
  static const Color divider = Color(0xFFE0E0E0);

  /// Overlay color (for modals, dialogs)
  static Color overlay = Colors.black.withOpacity(0.5);

  /// Shimmer base color (for loading states)
  static const Color shimmerBase = Color(0xFFE0E0E0);

  /// Shimmer highlight color
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================

  /// Hero section gradient
  static LinearGradient heroGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
  );

  /// Gold gradient (for premium features)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF4E5A0)],
  );

  // ============================================================================
  // OPACITY HELPERS
  // ============================================================================

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Black with various opacities
  static Color blackOpacity(double opacity) => black.withOpacity(opacity);

  /// White with various opacities
  static Color whiteOpacity(double opacity) => white.withOpacity(opacity);

  /// Gold with various opacities
  static Color goldOpacity(double opacity) => gold.withOpacity(opacity);
}
