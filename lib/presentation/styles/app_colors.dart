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
  // DEMO DESIGN-SYSTEM TOKENS (matching designwear_studio.html)
  // ============================================================================

  /// Marigold — primary remix/CTA accent from demo
  /// (matches the Design Studio mockup's `accent` token, #F5A623)
  static const Color marigold = Color(0xFFF5A623);

  /// Marigold ink — dark text on marigold backgrounds
  /// (matches the Design Studio mockup's `accentInk` token, #14161C)
  static const Color marigoldInk = Color(0xFF14161C);

  /// Like / heart accent
  static const Color like = Color(0xFFE5654B);

  /// Default garment fill colour
  static const Color garmentDefault = Color(0xFF27314F);

  /// Paper — warm light-mode background (demo --paper light)
  static const Color paperLight = Color(0xFFF1F0EC);

  /// Paper — dark-mode background (demo --paper dark)
  static const Color paperDark = Color(0xFF0D0F16);

  /// Card — light-mode card surface
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Card — dark-mode card surface
  static const Color cardDark = Color(0xFF151824);

  /// Ink — light-mode near-black
  static const Color inkLight = Color(0xFF15182B);

  /// Ink — dark-mode near-white
  static const Color inkDark = Color(0xFFF1F0EC);

  /// Hair — light-mode hairline border
  static const Color hairLight = Color(0xFFE4E2DA);

  /// Hair — dark-mode hairline border
  static const Color hairDark = Color(0xFF262B3D);

  /// Stone — secondary text
  static const Color stone = Color(0xFF7A7B82);

  // ============================================================================
  // DESIGN STUDIO MOCKUP TOKENS (exact hex match to the reference mockup)
  // ============================================================================
  //
  // The Design Studio mockup uses a three-tier surface hierarchy that the
  // legacy paper/card tokens above don't quite express (pageBg < barBg <
  // cardBg, increasing lightness), so these are additive, dedicated tokens
  // used only by the Design Studio screen and its panels.

  /// Page background behind the canvas area.
  static Color dsPageBg(bool isDark) =>
      isDark ? const Color(0xFF12151D) : const Color(0xFFF5F3EE);

  /// Top bar / left tools sidebar / right panel background.
  static Color dsBarBg(bool isDark) =>
      isDark ? const Color(0xFF171B25) : Colors.white;

  /// Card surface inside panels (layer cards, emoji tiles, shape swatches,
  /// placement rows).
  static Color dsCardBg(bool isDark) =>
      isDark ? const Color(0xFF1D2230) : const Color(0xFFF5F3EE);

  /// Hairline border.
  static Color dsBorder(bool isDark) =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x1A141414);

  /// Primary (high-contrast) text.
  static Color dsTextPrimary(bool isDark) =>
      isDark ? const Color(0xFFF5F6F8) : const Color(0xFF14161C);

  /// Secondary / muted text.
  static Color dsTextSecondary(bool isDark) =>
      isDark ? const Color(0xFF8B90A0) : const Color(0xFF6B6F7A);

  /// "Remixing an original tee" pill background.
  static Color dsPillBg(bool isDark) =>
      isDark ? const Color(0xFF1D2230) : const Color(0xFFF0EDE6);

  /// Accent color used for the active tool, garment badge, and primary CTAs.
  /// Same value in both themes — alias of [marigold].
  static const Color dsAccent = marigold;

  /// Ink color on top of accent-colored surfaces. Alias of [marigoldInk].
  static const Color dsAccentInk = marigoldInk;

  /// Publish button background.
  static Color dsPublishBg(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF14161C);

  /// Publish button text.
  static Color dsPublishText(bool isDark) =>
      isDark ? const Color(0xFF14161C) : Colors.white;

  /// White garment canvas-frame background — identical in both themes.
  static const Color dsCanvasFrame = Colors.white;

  /// Dark translucent chrome painted on top of the canvas frame (the
  /// front/back/left/right toggle, "from original" tag, print-size tag).
  /// This stays the same in both themes since it overlays the garment
  /// mockup, not the page.
  static const Color dsFrameChrome = Color(0xD9141418); // rgba(20,20,24,0.85)

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
