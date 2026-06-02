import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/utils/responsive_utils.dart';

/// Responsive typography utilities that scale based on device type
class ResponsiveTypography {
  /// Display text (largest)
  static TextStyle display(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 32.0,
      tablet: 40.0,
      desktop: 48.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }

  /// Heading 1
  static TextStyle h1(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 28.0,
      tablet: 32.0,
      desktop: 36.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }

  /// Heading 2
  static TextStyle h2(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }

  /// Heading 3
  static TextStyle h3(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }

  /// Heading 4
  static TextStyle h4(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }

  /// Body text (large)
  static TextStyle bodyLarge(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 16.0,
      tablet: 17.0,
      desktop: 18.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  /// Body text (default)
  static TextStyle body(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  /// Body text (small)
  static TextStyle bodySmall(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 12.0,
      tablet: 13.0,
      desktop: 14.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  /// Caption text
  static TextStyle caption(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  /// Button text
  static TextStyle button(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      letterSpacing: 1.0,
      color: color,
    );
  }

  /// Label text (uppercase, spaced)
  static TextStyle label(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 12.0,
      tablet: 13.0,
      desktop: 14.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      letterSpacing: 1.5,
      color: color,
    );
  }

  /// Price text
  static TextStyle price(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    final fontSize = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Colors.black,
    );
  }
}

