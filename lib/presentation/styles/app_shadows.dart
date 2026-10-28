import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized shadow definitions for the app
class AppShadows {
  // Private constructor to prevent instantiation
  AppShadows._();

  // ============================================================================
  // ELEVATION SHADOWS
  // ============================================================================

  /// Small shadow (elevation 2)
  static List<BoxShadow> get small => [
    BoxShadow(
      color: AppColors.blackOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium shadow (elevation 4)
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.blackOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Large shadow (elevation 8)
  static List<BoxShadow> get large => [
    BoxShadow(
      color: AppColors.blackOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Extra large shadow (elevation 16)
  static List<BoxShadow> get extraLarge => [
    BoxShadow(
      color: AppColors.blackOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // ============================================================================
  // COMPONENT SHADOWS
  // ============================================================================

  /// Card shadow
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.blackOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Product card shadow
  static List<BoxShadow> get productCard => [
    BoxShadow(
      color: AppColors.blackOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Bottom bar shadow (navigation, action bars)
  static List<BoxShadow> get bottomBar => [
    BoxShadow(
      color: AppColors.blackOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, -5),
    ),
  ];

  /// App bar shadow
  static List<BoxShadow> get appBar => [
    BoxShadow(
      color: AppColors.blackOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Button shadow
  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.blackOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Floating action button shadow
  static List<BoxShadow> get fab => [
    BoxShadow(
      color: AppColors.blackOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Modal/Dialog shadow
  static List<BoxShadow> get modal => [
    BoxShadow(
      color: AppColors.blackOpacity(0.15),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  /// Dropdown shadow
  static List<BoxShadow> get dropdown => [
    BoxShadow(
      color: AppColors.blackOpacity(0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================================================
  // SPECIAL SHADOWS
  // ============================================================================

  /// Inner shadow effect (for pressed states)
  static List<BoxShadow> get inner => [
    BoxShadow(
      color: AppColors.blackOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  /// Glow effect (for focus states)
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  /// Gold glow (for premium features)
  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: AppColors.goldOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  // ============================================================================
  // NO SHADOW
  // ============================================================================

  /// No shadow
  static List<BoxShadow> get none => [];
}
