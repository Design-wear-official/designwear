import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Responsive spacing utilities that scale based on device type
class ResponsiveSpacing {
  /// Extra small spacing
  static double xs(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 4.0,
      tablet: 6.0,
      desktop: 8.0,
    );
  }

  /// Small spacing
  static double sm(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// Medium spacing (default)
  static double md(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
  }

  /// Large spacing
  static double lg(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );
  }

  /// Extra large spacing
  static double xl(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 32.0,
      tablet: 48.0,
      desktop: 64.0,
    );
  }

  /// 2X Extra large spacing
  static double xxl(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 48.0,
      tablet: 64.0,
      desktop: 80.0,
    );
  }

  /// Horizontal padding (left + right)
  static EdgeInsets horizontalPadding(
    BuildContext context, {
    String size = 'md',
  }) {
    final spacing = _getSpacingBySize(context, size);
    return EdgeInsets.symmetric(horizontal: spacing);
  }

  /// Vertical padding (top + bottom)
  static EdgeInsets verticalPadding(
    BuildContext context, {
    String size = 'md',
  }) {
    final spacing = _getSpacingBySize(context, size);
    return EdgeInsets.symmetric(vertical: spacing);
  }

  /// All sides padding
  static EdgeInsets allPadding(BuildContext context, {String size = 'md'}) {
    final spacing = _getSpacingBySize(context, size);
    return EdgeInsets.all(spacing);
  }

  /// Custom padding with different sizes for horizontal and vertical
  static EdgeInsets customPadding(
    BuildContext context, {
    String horizontal = 'md',
    String vertical = 'md',
  }) {
    return EdgeInsets.symmetric(
      horizontal: _getSpacingBySize(context, horizontal),
      vertical: _getSpacingBySize(context, vertical),
    );
  }

  /// Page padding (standard padding for page content)
  static EdgeInsets pagePadding(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<EdgeInsets>(
      context,
      mobile: const EdgeInsets.all(20),
      tablet: const EdgeInsets.all(32),
      desktop: const EdgeInsets.all(48),
    );
  }

  /// Section padding (padding between major sections)
  static EdgeInsets sectionPadding(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue<EdgeInsets>(
      context,
      mobile: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      tablet: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      desktop: const EdgeInsets.symmetric(vertical: 48, horizontal: 48),
    );
  }

  /// Helper method to get spacing value by size string
  static double _getSpacingBySize(BuildContext context, String size) {
    switch (size.toLowerCase()) {
      case 'xs':
        return xs(context);
      case 'sm':
        return sm(context);
      case 'md':
        return md(context);
      case 'lg':
        return lg(context);
      case 'xl':
        return xl(context);
      case 'xxl':
        return xxl(context);
      default:
        return md(context);
    }
  }
}

/// Responsive SizedBox widgets for spacing
class ResponsiveGap {
  /// Horizontal gap
  static Widget horizontal(BuildContext context, {String size = 'md'}) {
    return SizedBox(width: ResponsiveSpacing._getSpacingBySize(context, size));
  }

  /// Vertical gap
  static Widget vertical(BuildContext context, {String size = 'md'}) {
    return SizedBox(height: ResponsiveSpacing._getSpacingBySize(context, size));
  }
}
