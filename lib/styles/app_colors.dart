import 'package:flutter/material.dart';

/// Centralized color palette for the DesignWear app
/// This is the single source of truth for all colors used in the app
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // BRAND COLORS
  // ============================================================================

  /// Primary brand color - Deep Charcoal
  static const Color black = Color(0xFF0D0D12);

  /// Secondary brand color - Vibrant Gold
  static const Color gold = Color(0xFFFFD700);

  /// Accent color - Neon Purple/Blue
  static const Color purple = Color(0xFF8A2BE2);
  static const Color accentBlue = Color(0xFF00F0FF);

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================

  /// Pure white
  static const Color white = Colors.white;

  /// Background color for the app (Dark)
  static const Color background = Color(0xFF0D0D12);

  /// Surface color for cards and elevated elements
  static const Color surface = Color(0xFF1E1E2A);

  /// Light gray background (for subtle backgrounds)
  static const Color backgroundLight = Color(0xFF1A1A24);

  /// Gray shades (adapted for dark mode)
  static const Color gray50 = Color(0xFF1E1E2A);
  static const Color gray100 = Color(0xFF252533);
  static const Color gray200 = Color(0xFF2C2C3D);
  static const Color gray300 = Color(0xFF38384D);
  static const Color gray400 = Color(0xFF4B4B63);
  static const Color gray500 = Color(0xFF62627A);
  static const Color gray600 = Color(0xFF7D7D95);
  static const Color gray700 = Color(0xFF9E9EB3);
  static const Color gray800 = Color(0xFFC3C3D1);
  static const Color gray900 = Color(0xFFE6E6EE);

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

  /// Primary text color (white for dark mode)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text color (light gray)
  static const Color textSecondary = Color(0xFFAAAAAA);

  /// Disabled text color (dark gray)
  static const Color textDisabled = Color(0xFF62627A);

  /// Hint text color
  static const Color textHint = Color(0xFF62627A);

  /// Text on dark backgrounds
  static const Color textOnDark = Colors.white;

  /// Text on gold/accent backgrounds
  static const Color textOnGold = Color(0xFF0D0D12);

  // ============================================================================
  // BORDER COLORS
  // ============================================================================

  /// Default border color (Glass border)
  static const Color border = Color(0x33FFFFFF); // 20% white

  /// Light border color
  static const Color borderLight = Color(0x1AFFFFFF); // 10% white

  /// Dark border color
  static const Color borderDark = Color(0x4DFFFFFF); // 30% white

  /// Focus/Active border color
  static const Color borderFocus = accentBlue;

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
    colors: [Color(0xFF0D0D12), Colors.transparent],
  );

  /// Gold gradient (for premium features)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );

  /// Accent gradient (neon)
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFF00F0FF)],
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
