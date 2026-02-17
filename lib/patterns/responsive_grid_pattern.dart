import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Configuration for responsive grid pattern
class ResponsiveGridConfig {
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double mobileAspectRatio;
  final double tabletAspectRatio;
  final double desktopAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGridConfig({
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.mobileAspectRatio = 0.75,
    this.tabletAspectRatio = 0.65,
    this.desktopAspectRatio = 0.60,
    this.crossAxisSpacing = 20,
    this.mainAxisSpacing = 32,
  });

  /// Default configuration for product grids
  static const ResponsiveGridConfig productGrid = ResponsiveGridConfig(
    mobileColumns: 2,
    tabletColumns: 3,
    desktopColumns: 4,
    mobileAspectRatio: 0.75,
    tabletAspectRatio: 0.65,
    desktopAspectRatio: 0.60,
  );

  /// Configuration for dense grids (more items per row)
  static const ResponsiveGridConfig denseGrid = ResponsiveGridConfig(
    mobileColumns: 2,
    tabletColumns: 4,
    desktopColumns: 5,
    mobileAspectRatio: 0.8,
    tabletAspectRatio: 0.7,
    desktopAspectRatio: 0.65,
  );
}

/// Responsive grid pattern widget that automatically adjusts based on device type
class ResponsiveGridPattern extends StatelessWidget {
  final List<Widget> children;
  final ResponsiveGridConfig config;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridPattern({
    super.key,
    required this.children,
    this.config = ResponsiveGridConfig.productGrid,
    this.padding,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getResponsiveValue<int>(
      context,
      mobile: config.mobileColumns,
      tablet: config.tabletColumns,
      desktop: config.desktopColumns,
    );

    final childAspectRatio = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: config.mobileAspectRatio,
      tablet: config.tabletAspectRatio,
      desktop: config.desktopAspectRatio,
    );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: config.crossAxisSpacing,
        mainAxisSpacing: config.mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Builder-based responsive grid for more complex use cases
class ResponsiveGridBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ResponsiveGridConfig config;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.config = ResponsiveGridConfig.productGrid,
    this.padding,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getResponsiveValue<int>(
      context,
      mobile: config.mobileColumns,
      tablet: config.tabletColumns,
      desktop: config.desktopColumns,
    );

    final childAspectRatio = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: config.mobileAspectRatio,
      tablet: config.tabletAspectRatio,
      desktop: config.desktopAspectRatio,
    );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: config.crossAxisSpacing,
        mainAxisSpacing: config.mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
