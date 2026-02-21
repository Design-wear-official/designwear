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

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLgBR,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(
            color: AppColors.black,
            width: AppDimensions.borderWidthMd,
          ),
          padding: AppDimensions.buttonPadding,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLgBR,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          padding: AppDimensions.buttonPadding,
          textStyle: AppTextStyles.button,
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

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLgBR,
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
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
    // TODO: Implement dark theme when needed
    return lightTheme;
  }
}
