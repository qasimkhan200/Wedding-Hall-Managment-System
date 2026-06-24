import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';
import 'responsive_theme.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: ResponsiveTheme.appBarTheme.copyWith(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ResponsiveTheme.elevatedButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ResponsiveTheme.outlinedButtonStyle.copyWith(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          side: WidgetStateProperty.all(
              const BorderSide(color: AppColors.primary)),
        ),
      ),
      inputDecorationTheme: ResponsiveTheme.inputDecorationTheme.copyWith(
        fillColor: AppColors.inputBackground,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: 14.sp,
        ),
      ),
      cardTheme: ResponsiveTheme.cardTheme.copyWith(
        color: AppColors.surface,
      ),
      listTileTheme: ResponsiveTheme.listTileTheme,
      iconTheme: ResponsiveTheme.iconTheme,
      chipTheme: ResponsiveTheme.chipTheme,
      dialogTheme: ResponsiveTheme.dialogTheme,
      bottomSheetTheme: ResponsiveTheme.bottomSheetTheme,
      tabBarTheme: ResponsiveTheme.tabBarTheme,
      floatingActionButtonTheme: ResponsiveTheme.floatingActionButtonTheme,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: ResponsiveTheme.displayLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: ResponsiveTheme.displayMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        displaySmall: ResponsiveTheme.displaySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineLarge: ResponsiveTheme.headlineLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineMedium: ResponsiveTheme.headlineMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineSmall: ResponsiveTheme.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        titleLarge: ResponsiveTheme.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        titleMedium: ResponsiveTheme.titleMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        titleSmall: ResponsiveTheme.titleSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: ResponsiveTheme.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: ResponsiveTheme.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: ResponsiveTheme.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        labelLarge: ResponsiveTheme.labelLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        labelMedium: ResponsiveTheme.labelMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        labelSmall: ResponsiveTheme.labelSmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
