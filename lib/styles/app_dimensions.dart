import 'package:flutter/material.dart';

/// Centralized dimensions for spacing, sizing, and layout
/// This is the single source of truth for all dimensional values
class AppDimensions {
  // Private constructor to prevent instantiation
  AppDimensions._();

  // ============================================================================
  // SPACING SCALE
  // ============================================================================

  /// Extra small spacing (4px)
  static const double spacingXs = 4.0;

  /// Small spacing (8px)
  static const double spacingSm = 8.0;

  /// Medium spacing (16px) - Default
  static const double spacingMd = 16.0;

  /// Large spacing (24px)
  static const double spacingLg = 24.0;

  /// Extra large spacing (32px)
  static const double spacingXl = 32.0;

  /// 2X Extra large spacing (48px)
  static const double spacingXxl = 48.0;

  /// 3X Extra large spacing (64px)
  static const double spacingXxxl = 64.0;

  // ============================================================================
  // PADDING
  // ============================================================================

  /// Page padding (horizontal)
  static const double pagePaddingHorizontal = 20.0;

  /// Page padding (vertical)
  static const double pagePaddingVertical = 24.0;

  /// Page padding (all sides)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pagePaddingHorizontal,
    vertical: pagePaddingVertical,
  );

  /// Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  /// Section padding
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 32.0,
  );

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );

  /// Input field padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// No border radius (sharp corners)
  static const double borderRadiusNone = 0.0;

  /// Small border radius
  static const double borderRadiusSm = 4.0;

  /// Medium border radius
  static const double borderRadiusMd = 8.0;

  /// Large border radius
  static const double borderRadiusLg = 12.0;

  /// Extra large border radius
  static const double borderRadiusXl = 16.0;

  /// Round border radius (circular)
  static const double borderRadiusRound = 999.0;

  /// BorderRadius objects for convenience
  static BorderRadius get borderRadiusNoneBR =>
      BorderRadius.circular(borderRadiusNone);
  static BorderRadius get borderRadiusSmBR =>
      BorderRadius.circular(borderRadiusSm);
  static BorderRadius get borderRadiusMdBR =>
      BorderRadius.circular(borderRadiusMd);
  static BorderRadius get borderRadiusLgBR =>
      BorderRadius.circular(borderRadiusLg);
  static BorderRadius get borderRadiusXlBR =>
      BorderRadius.circular(borderRadiusXl);
  static BorderRadius get borderRadiusRoundBR =>
      BorderRadius.circular(borderRadiusRound);

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Small icon size
  static const double iconSizeSm = 16.0;

  /// Medium icon size (default)
  static const double iconSizeMd = 24.0;

  /// Large icon size
  static const double iconSizeLg = 32.0;

  /// Extra large icon size
  static const double iconSizeXl = 48.0;

  // ============================================================================
  // BUTTON SIZES
  // ============================================================================

  /// Button minimum height
  static const double buttonHeight = 56.0;

  /// Small button height
  static const double buttonHeightSm = 40.0;

  /// Large button height
  static const double buttonHeightLg = 64.0;

  // ============================================================================
  // BORDER WIDTH
  // ============================================================================

  /// Thin border
  static const double borderWidthThin = 1.0;

  /// Medium border
  static const double borderWidthMd = 1.5;

  /// Thick border
  static const double borderWidthThick = 2.0;

  // ============================================================================
  // CONTAINER SIZES
  // ============================================================================

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height
  static const double bottomNavBarHeight = 60.0;

  /// Card elevation
  static const double cardElevation = 2.0;

  /// Hero section height (mobile)
  static const double heroSectionHeight = 240.0;

  /// Design studio banner height
  static const double designStudioBannerHeight = 140.0;

  /// Category chip height
  static const double categoryChipHeight = 50.0;

  /// Product card image aspect ratio
  static const double productCardAspectRatio = 0.75;

  // ============================================================================
  // GRID SPACING
  // ============================================================================

  /// Grid cross axis spacing
  static const double gridCrossAxisSpacing = 20.0;

  /// Grid main axis spacing
  static const double gridMainAxisSpacing = 32.0;

  // ============================================================================
  // DIVIDER
  // ============================================================================

  /// Divider thickness
  static const double dividerThickness = 1.0;

  /// Divider indent
  static const double dividerIndent = 0.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Fast animation duration (150ms)
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Normal animation duration (300ms)
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Slow animation duration (500ms)
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // CONSTRAINTS
  // ============================================================================

  /// Maximum content width (for large screens)
  static const double maxContentWidth = 1400.0;

  /// Maximum card width
  static const double maxCardWidth = 400.0;

  /// Minimum touch target size (accessibility)
  static const double minTouchTarget = 48.0;
}
