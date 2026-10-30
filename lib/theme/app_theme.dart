import 'package:flutter/material.dart';

import '../presentation/styles/styles.dart';

export '../presentation/styles/styles.dart' show AppColors, AppTheme;

/// The app uses the original DesignWear theme (see lib/presentation/styles).
ThemeData buildAppTheme([Brightness brightness = Brightness.dark]) {
  final dark = brightness == Brightness.dark;
  final base = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return base.copyWith(
    // The original dark scheme puts white text on a cyan primary (1.4:1), which
    // is unreadable on plain buttons. Keep its colours, fix the label colour.
    colorScheme: base.colorScheme.copyWith(
      // Gold is the brand accent everywhere (buttons, switches, progress,
      // selected chips); darkened on light backgrounds so it stays readable.
      primary: dark ? AppColors.marigold : const Color(0xFF9A5B00),
      onPrimary: dark ? AppColors.marigoldInk : Colors.white,
    ),
    // The original app bar title style has no colour, so titles (Profile,
    // Settings, ...) drew white on the light theme's off-white bar. Give it the
    // bar's own foreground colour.
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        color: base.appBarTheme.foregroundColor,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: dark ? AppColors.marigold : const Color(0xFF9A5B00),
    ),
    // Primary calls to action look like the original "Join & remix" button.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.marigold,
        foregroundColor: AppColors.marigoldInk,
        disabledBackgroundColor: AppColors.marigold.withValues(alpha: 0.35),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Colours that must change with the theme to stay readable.
extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Secondary text.
  Color get muted => isDark ? AppColors.textSecondary : AppColors.stone;

  /// "In stock" green, dark enough on a white background.
  Color get success => isDark ? AppColors.success : const Color(0xFF2E7D32);

  /// Accent for prices and links: the original marigold, darkened on light
  /// backgrounds so it stays readable.
  Color get accent => isDark ? AppColors.marigold : const Color(0xFF9A5B00);

  Color get paper => isDark ? AppColors.paperDark : AppColors.paperLight;
  Color get ink => isDark ? AppColors.inkDark : AppColors.inkLight;
  Color get hair => isDark ? AppColors.hairDark : AppColors.hairLight;
  Color get card => isDark ? AppColors.cardDark : AppColors.cardLight;
}
