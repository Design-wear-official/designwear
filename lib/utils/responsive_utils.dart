import 'package:flutter/material.dart';

/// Device type enumeration for responsive design
enum DeviceType { mobile, tablet, desktop }

/// Responsive breakpoint constants
class ResponsiveBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1400;
}

/// Core responsive utilities for device detection and responsive values
class ResponsiveUtils {
  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveBreakpoints.tablet) {
      return DeviceType.mobile;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Get responsive value based on device type
  /// Returns the appropriate value for the current device type
  /// If a value is not provided for a device type, it falls back to the next smaller size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if screen width is greater than a specific breakpoint
  static bool isWidthGreaterThan(BuildContext context, double breakpoint) {
    return getScreenWidth(context) > breakpoint;
  }

  /// Check if screen width is less than a specific breakpoint
  static bool isWidthLessThan(BuildContext context, double breakpoint) {
    return getScreenWidth(context) < breakpoint;
  }
}
