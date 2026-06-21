import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Complete theme configuration for the DesignWear app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme — warm off-white for premium feel
      primaryColor: const Color(0xFFF5F4F0),
      scaffoldBackgroundColor: const Color(0xFFF5F4F0),
      colorScheme: const ColorScheme.light(
        primary: AppColors.purple,
        secondary: AppColors.gold,
        surface: Color(0xFFFFFFFF),
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.textOnGold,
        onSurface: Color(0xFF0D0D12),
        onError: AppColors.white,
      ),

      // Text Theme
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h4,
        titleMedium: AppTextStyles.h5,
        titleSmall: AppTextStyles.h6,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F4F0),
        foregroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h4,
        iconTheme: const IconThemeData(
          color: AppColors.black,
          size: AppDimensions.iconSizeMd,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.black.withOpacity(0.38);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.black.withOpacity(0.82);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.black.withOpacity(0.72);
            }
            return AppColors.black;
          }),
          foregroundColor: WidgetStatePropertyAll(AppColors.white),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withOpacity(0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return Colors.white.withOpacity(0.12);
            }
            return null;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 2;
            if (states.contains(WidgetState.pressed)) return 0;
            return 0;
          }),
          padding: WidgetStatePropertyAll(AppDimensions.buttonPadding),
          minimumSize:
              const WidgetStatePropertyAll(Size(0, AppDimensions.buttonHeight)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLgBR,
          )),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.forbidden;
            }
            return SystemMouseCursors.click;
          }),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.black),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return const BorderSide(
                color: AppColors.black,
                width: AppDimensions.borderWidthThick,
              );
            }
            return const BorderSide(
              color: AppColors.black,
              width: AppDimensions.borderWidthMd,
            );
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.black.withOpacity(0.06);
            }
            if (states.contains(WidgetState.focused)) {
              return AppColors.black.withOpacity(0.08);
            }
            return null;
          }),
          padding: WidgetStatePropertyAll(AppDimensions.buttonPadding),
          minimumSize:
              const WidgetStatePropertyAll(Size(0, AppDimensions.buttonHeight)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLgBR,
          )),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.forbidden;
            }
            return SystemMouseCursors.click;
          }),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.gold),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.gold.withOpacity(0.08);
            }
            return null;
          }),
          padding: WidgetStatePropertyAll(AppDimensions.buttonPadding),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: AppDimensions.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        errorStyle: AppTextStyles.error,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLgBR,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(AppDimensions.spacingMd),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.spacingMd,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.black,
        size: AppDimensions.iconSizeMd,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray900,
        selectedColor: AppColors.gold,
        disabledColor: AppColors.gray800,
        labelStyle: AppTextStyles.bodySmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusRound),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textOnGold,
        elevation: 6,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLgBR,
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.black),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.black),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.button,
        unselectedLabelStyle: AppTextStyles.button,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.gold,
            width: AppDimensions.borderWidthThick,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DARK THEME (Optional - for future dark mode support)
  // ============================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      primaryColor: AppColors.background,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textOnGold,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),

      // Text Theme — apply white color so text is visible on dark backgrounds
      textTheme: GoogleFonts.outfitTextTheme()
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            displayLarge: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            displayMedium: AppTextStyles.displayMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            displaySmall: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            headlineLarge: AppTextStyles.h1.copyWith(
              color: AppColors.textPrimary,
            ),
            headlineMedium: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
            ),
            headlineSmall: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
            ),
            titleLarge: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            titleMedium: AppTextStyles.h5.copyWith(
              color: AppColors.textPrimary,
            ),
            titleSmall: AppTextStyles.h6.copyWith(color: AppColors.textPrimary),
            bodyLarge: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            bodyMedium: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            bodySmall: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            labelLarge: AppTextStyles.button.copyWith(
              color: AppColors.textPrimary,
            ),
            labelMedium: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
            ),
            labelSmall: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h4,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppDimensions.iconSizeMd,
        ),
      ),

      // Elevated Button Theme — use accentBlue instead of black so button is visible on dark background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.accentBlue.withOpacity(0.38);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.accentBlue.withOpacity(0.85);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.accentBlue.withOpacity(0.75);
            }
            return AppColors.accentBlue;
          }),
          foregroundColor: WidgetStatePropertyAll(AppColors.white),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withOpacity(0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return Colors.white.withOpacity(0.12);
            }
            return null;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 2;
            return 0;
          }),
          padding: WidgetStatePropertyAll(AppDimensions.buttonPadding),
          minimumSize:
              const WidgetStatePropertyAll(Size(0, AppDimensions.buttonHeight)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLgBR,
          )),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.forbidden;
            }
            return SystemMouseCursors.click;
          }),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.textPrimary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return const BorderSide(
                color: AppColors.textPrimary,
                width: AppDimensions.borderWidthThick,
              );
            }
            return const BorderSide(
              color: AppColors.textSecondary,
              width: AppDimensions.borderWidthMd,
            );
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.textPrimary.withOpacity(0.06);
            }
            return null;
          }),
          padding: WidgetStatePropertyAll(AppDimensions.buttonPadding),
          minimumSize:
              const WidgetStatePropertyAll(Size(0, AppDimensions.buttonHeight)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLgBR,
          )),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.forbidden;
            }
            return SystemMouseCursors.click;
          }),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.gold),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.gold.withOpacity(0.08);
            }
            return null;
          }),
          padding: WidgetStatePropertyAll(AppDimensions.buttonPadding),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: AppDimensions.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthMd,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        errorStyle: AppTextStyles.error,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLgBR,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(AppDimensions.spacingMd),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.spacingMd,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppDimensions.iconSizeMd,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        selectedColor: AppColors.gold,
        disabledColor: AppColors.gray200,
        labelStyle: AppTextStyles.bodySmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusRound),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textOnGold,
        elevation: 6,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMdBR,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme — use dark surface so dialog text is visible in dark mode
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLgBR,
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.button,
        unselectedLabelStyle: AppTextStyles.button,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.gold,
            width: AppDimensions.borderWidthThick,
          ),
        ),
      ),
    );
  }
}
