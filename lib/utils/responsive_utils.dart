import 'package:flutter/material.dart';

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

  /// Get phone size sub-type (only meaningful on mobile)
  static PhoneSize getPhoneSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.phoneSmall) return PhoneSize.small;
    if (width < ResponsiveBreakpoints.phoneMedium) return PhoneSize.medium;
    if (width < ResponsiveBreakpoints.phoneLarge) return PhoneSize.large;
    return PhoneSize.xlarge;
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

/// Concrete size values for common UI elements — use these instead of
/// hardcoded pixel heights to prevent overflow/overlap across phone sizes.
class ResponsiveSizes {
  /// Hero/banner section height
  /// Small phone: 180, Medium: 210, Large: 240, XLarge: 260, Tablet: 320
  static double heroHeight(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 180,
      medium: 210,
      large: 240,
      xlarge: 260,
      tablet: 320,
    );
  }

  /// Design Studio / secondary banner height
  /// Small: 110, Medium: 120, Large: 130, XLarge: 140, Tablet: 180
  static double bannerHeight(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 110,
      medium: 120,
      large: 130,
      xlarge: 140,
      tablet: 180,
    );
  }

  /// Product carousel card height
  /// Small: 300, Medium: 340, Large: 370, XLarge: 400, Tablet: 480
  static double carouselHeight(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 300,
      medium: 340,
      large: 370,
      xlarge: 400,
      tablet: 480,
    );
  }

  /// Product card height (grid items)
  /// Small: 220, Medium: 250, Large: 270, XLarge: 290, Tablet: 340
  static double cardHeight(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 220,
      medium: 250,
      large: 270,
      xlarge: 290,
      tablet: 340,
    );
  }

  /// Horizontal screen padding
  /// Small: 12, Medium: 16, Large: 18, XLarge: 20, Tablet: 32
  static double horizontalPadding(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 12,
      medium: 16,
      large: 18,
      xlarge: 20,
      tablet: 32,
    );
  }

  /// Vertical section padding
  /// Small: 8, Medium: 10, Large: 12, XLarge: 12, Tablet: 16
  static double verticalPadding(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 8,
      medium: 10,
      large: 12,
      xlarge: 12,
      tablet: 16,
    );
  }

  /// Page EdgeInsets (horizontal + vertical combined)
  static EdgeInsets pagePadding(BuildContext context) {
    final h = horizontalPadding(context);
    final v = verticalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  /// Standard content padding (inside cards / sections)
  static EdgeInsets contentPadding(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<EdgeInsets>(
      context,
      small: const EdgeInsets.all(12),
      medium: const EdgeInsets.all(14),
      large: const EdgeInsets.all(16),
      xlarge: const EdgeInsets.all(20),
      tablet: const EdgeInsets.all(28),
    );
  }

  /// Button vertical padding
  static double buttonPaddingVertical(BuildContext context) {
    return ResponsiveUtils.getPhoneValue<double>(
      context,
      small: 12,
      medium: 14,
      large: 15,
      xlarge: 16,
      tablet: 18,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE TEXT STYLES
// Context-aware font sizes that scale across phone breakpoints.
// Use these instead of AppTextStyles.* when you need phone-adaptive sizes.
// ─────────────────────────────────────────────────────────────────────────────

/// Responsive text styles — mirrors AppTextStyles but scales per phone size.
/// All methods return a [TextStyle] using the Google Fonts Outfit family.
class ResponsiveTextStyles {
  ResponsiveTextStyles._();

  // Display / Hero
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 36, medium: 40, large: 44, xlarge: 48, tablet: 56,
    ),
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle displaySmall(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 24, medium: 28, large: 30, xlarge: 32, tablet: 38,
    ),
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // Headings
  static TextStyle h1(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 22, medium: 24, large: 26, xlarge: 28, tablet: 34,
    ),
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static TextStyle h2(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 19, medium: 21, large: 22, xlarge: 24, tablet: 28,
    ),
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static TextStyle h3(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 16, medium: 17, large: 18, xlarge: 20, tablet: 24,
    ),
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle h4(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 14, medium: 15, large: 16, xlarge: 18, tablet: 22,
    ),
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 15, medium: 16, large: 17, xlarge: 18, tablet: 20,
    ),
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 13, medium: 14, large: 15, xlarge: 16, tablet: 18,
    ),
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 11, medium: 12, large: 13, xlarge: 14, tablet: 16,
    ),
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  // Price
  static TextStyle priceLarge(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 19, medium: 20, large: 22, xlarge: 24, tablet: 28,
    ),
    fontWeight: FontWeight.bold,
  );

  static TextStyle priceSmall(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 14, medium: 15, large: 16, xlarge: 18, tablet: 20,
    ),
    fontWeight: FontWeight.bold,
  );

  // Button label
  static TextStyle button(BuildContext context) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: ResponsiveUtils.getPhoneValue<double>(
      context, small: 13, medium: 14, large: 15, xlarge: 16, tablet: 18,
    ),
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE DIMENSIONS
// Context-aware replacements for AppDimensions layout-critical constants.
// Use these for padding/spacing values that need to shrink on small phones.
// ─────────────────────────────────────────────────────────────────────────────

/// Context-aware spacing and dimension helpers.
/// Mirrors the API of [AppDimensions] but adapts to phone screen size.
class ResponsiveDimensions {
  ResponsiveDimensions._();

  // Spacing scale
  static double spacingXs(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 3, medium: 4, large: 4, xlarge: 4, tablet: 6,
      );

  static double spacingSm(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 6, medium: 8, large: 8, xlarge: 8, tablet: 12,
      );

  static double spacingMd(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 12, medium: 14, large: 16, xlarge: 16, tablet: 24,
      );

  static double spacingLg(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 18, medium: 20, large: 22, xlarge: 24, tablet: 32,
      );

  static double spacingXl(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 24, medium: 28, large: 30, xlarge: 32, tablet: 48,
      );

  // Button
  static EdgeInsets buttonPadding(BuildContext context) {
    final v = ResponsiveSizes.buttonPaddingVertical(context);
    final h = ResponsiveSizes.horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  static double buttonHeight(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 44, medium: 48, large: 52, xlarge: 56, tablet: 60,
      );

  // Input field padding
  static EdgeInsets inputPadding(BuildContext context) {
    final h = ResponsiveSizes.horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: spacingSm(context));
  }

  // Icon sizes
  static double iconMd(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 20, medium: 22, large: 24, xlarge: 24, tablet: 28,
      );

  static double iconLg(BuildContext context) =>
      ResponsiveUtils.getPhoneValue<double>(
        context, small: 26, medium: 28, large: 30, xlarge: 32, tablet: 40,
      );
}
