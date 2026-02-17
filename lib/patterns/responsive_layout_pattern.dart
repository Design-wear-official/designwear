import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Responsive builder that provides device type to builder function
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive layout with separate builders for mobile, tablet, and desktop
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile(context);
      case DeviceType.tablet:
        return (tablet ?? mobile)(context);
      case DeviceType.desktop:
        return (desktop ?? tablet ?? mobile)(context);
    }
  }
}

/// Responsive value widget that returns different widgets based on device type
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveUtils.getResponsiveValue<T>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return builder(context, value);
  }
}

/// Responsive container with automatic padding and constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final Color? color;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.color,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding =
        padding ??
        ResponsiveUtils.getResponsiveValue<EdgeInsets>(
          context,
          mobile: const EdgeInsets.all(20),
          tablet: const EdgeInsets.all(32),
          desktop: const EdgeInsets.all(48),
        );

    final responsiveMaxWidth =
        maxWidth ??
        ResponsiveUtils.getResponsiveValue<double>(
          context,
          mobile: double.infinity,
          tablet: 1024,
          desktop: 1400,
        );

    return Container(
      padding: responsivePadding,
      constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
      color: color,
      decoration: decoration,
      child: child,
    );
  }
}

/// Responsive row/column that switches between row and column based on device
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool forceColumn;
  final bool forceRow;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.forceColumn = false,
    this.forceRow = false,
  });

  @override
  Widget build(BuildContext context) {
    if (forceColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    if (forceRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }
  }
}
