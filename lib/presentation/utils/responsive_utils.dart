import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Device type enumeration for responsive design
enum DeviceType { mobile, tablet, desktop }

/// Phone sub-type for fine-grained mobile sizing
enum PhoneSize {
  small, // < 360dp  (Galaxy A series small)
  medium, // 360–389dp (Galaxy S, standard Android)
  large, // 390–411dp (Pixel 6/7, iPhone 14)
  xlarge, // >= 412dp  (Pixel 7 Pro, large Androids)
}

/// Responsive breakpoint constants
class ResponsiveBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1400;

  // Phone-specific sub-breakpoints
  static const double phoneSmall = 360;
  static const double phoneMedium = 390;
  static const double phoneLarge = 412;
}

/// Core responsive utilities backed by flutter_screenutil (390×844 canvas).
/// Use the `.w`, `.h`, `.sp`, `.r` num extensions directly for new code.
class ResponsiveUtils {
  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = ScreenUtil().screenWidth;

    if (width < ResponsiveBreakpoints.tablet) {
      return DeviceType.mobile;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Get phone size sub-type (only meaningful on mobile)
  static PhoneSize getPhoneSize(BuildContext context) {
    final width = ScreenUtil().screenWidth;
    if (width < ResponsiveBreakpoints.phoneSmall) return PhoneSize.small;
    if (width < ResponsiveBreakpoints.phoneMedium) return PhoneSize.medium;
    if (width < ResponsiveBreakpoints.phoneLarge) return PhoneSize.large;
    return PhoneSize.xlarge;
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Get responsive value based on device type
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get value based on phone sub-size (falls back gracefully for tablets/desktop)
  static T getPhoneValue<T>(
    BuildContext context, {
    required T small,
    required T medium,
    required T large,
    required T xlarge,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    if (deviceType == DeviceType.tablet) return tablet ?? xlarge;
    if (deviceType == DeviceType.desktop) return desktop ?? tablet ?? xlarge;

    switch (getPhoneSize(context)) {
      case PhoneSize.small:
        return small;
      case PhoneSize.medium:
        return medium;
      case PhoneSize.large:
        return large;
      case PhoneSize.xlarge:
        return xlarge;
    }
  }

  /// Screen width in logical pixels (from ScreenUtil)
  static double getScreenWidth(BuildContext context) =>
      ScreenUtil().screenWidth;

  /// Screen height in logical pixels (from ScreenUtil)
  static double getScreenHeight(BuildContext context) =>
      ScreenUtil().screenHeight;

  /// Check if screen width is greater than a specific breakpoint
  static bool isWidthGreaterThan(BuildContext context, double breakpoint) =>
      ScreenUtil().screenWidth > breakpoint;

  /// Check if screen width is less than a specific breakpoint
  static bool isWidthLessThan(BuildContext context, double breakpoint) =>
      ScreenUtil().screenWidth < breakpoint;
}

/// Convenience class for common responsive sizes using ScreenUtil scaling.
/// All values are scaled relative to the 390×844 design canvas.
class ResponsiveSizes {
  static EdgeInsets contentPadding(BuildContext context) =>
      EdgeInsets.all(16.w);

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h);

  static EdgeInsets horizontalPaddingOnly(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 16.w);

  static double horizontalPadding(BuildContext context) => 16.w;

  static double verticalPadding(BuildContext context) => 12.h;

  static double buttonPaddingVertical(BuildContext context) => 14.h;

  static double cardBorderRadius(BuildContext context) => 12.r;

  static double iconSize(BuildContext context) => 24.w;

  /// Height for promotional banners (sidebar / mobile)
  static double bannerHeight(BuildContext context) => 160.h;

  /// Height for image carousels (virtual try-on, product gallery)
  static double carouselHeight(BuildContext context) => 260.h;
}
