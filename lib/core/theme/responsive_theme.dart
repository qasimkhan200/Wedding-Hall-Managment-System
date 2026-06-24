import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/responsive_utils.dart';

class ResponsiveTheme {
  // Responsive text styles
  static TextStyle get displayLarge => TextStyle(
        fontSize: ResponsiveUtils.headline1,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: ResponsiveUtils.headline2,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => TextStyle(
        fontSize: ResponsiveUtils.headline3,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontSize: ResponsiveUtils.headline4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: ResponsiveUtils.headline5,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontSize: ResponsiveUtils.headline6,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: ResponsiveUtils.subtitle1,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: ResponsiveUtils.subtitle2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get titleSmall => TextStyle(
        fontSize: ResponsiveUtils.body1,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontSize: ResponsiveUtils.body1,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: ResponsiveUtils.body2,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: ResponsiveUtils.caption,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      );

  static TextStyle get labelLarge => TextStyle(
        fontSize: ResponsiveUtils.body2,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: ResponsiveUtils.caption,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      );

  // Responsive button styles
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, ResponsiveUtils.buttonHeight),
        padding: ResponsiveUtils.paddingVerticalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        textStyle: TextStyle(
          fontSize: ResponsiveUtils.body1,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, ResponsiveUtils.buttonHeight),
        padding: ResponsiveUtils.paddingVerticalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        textStyle: TextStyle(
          fontSize: ResponsiveUtils.body1,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        minimumSize: Size(double.infinity, ResponsiveUtils.buttonHeight),
        padding: ResponsiveUtils.paddingVerticalMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        textStyle: TextStyle(
          fontSize: ResponsiveUtils.body1,
          fontWeight: FontWeight.w600,
        ),
      );

  // Responsive input decoration
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        contentPadding: ResponsiveUtils.paddingMd,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
      );

  // Responsive card theme
  static CardThemeData get cardTheme => CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        margin: ResponsiveUtils.paddingSm,
      );

  // Responsive app bar theme
  static AppBarThemeData get appBarTheme => AppBarThemeData(
        toolbarHeight: ResponsiveUtils.buttonHeightLarge,
        titleTextStyle: TextStyle(
          fontSize: ResponsiveUtils.headline6,
          fontWeight: FontWeight.w600,
        ),
      );

  // Responsive list tile theme
  static ListTileThemeData get listTileTheme => ListTileThemeData(
        contentPadding: ResponsiveUtils.paddingHorizontalMd,
        minLeadingWidth: ResponsiveUtils.iconLg,
      );

  // Responsive icon theme
  static IconThemeData get iconTheme => IconThemeData(
        size: ResponsiveUtils.iconMd,
      );

  // Responsive chip theme
  static ChipThemeData get chipTheme => ChipThemeData(
        padding: ResponsiveUtils.paddingHorizontalSm,
        labelPadding: ResponsiveUtils.paddingHorizontalXs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusSm),
        ),
      );

  // Responsive dialog theme
  static DialogThemeData get dialogTheme => DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.radiusLg),
        ),
        contentTextStyle: TextStyle(fontSize: ResponsiveUtils.body1),
        titleTextStyle: TextStyle(
          fontSize: ResponsiveUtils.headline6,
          fontWeight: FontWeight.w600,
        ),
      );

  // Responsive bottom sheet theme
  static BottomSheetThemeData get bottomSheetTheme => BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveUtils.radiusLg),
          ),
        ),
      );

  // Responsive tab bar theme
  static TabBarThemeData get tabBarTheme => TabBarThemeData(
        labelStyle: TextStyle(
          fontSize: ResponsiveUtils.body2,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ResponsiveUtils.body2,
          fontWeight: FontWeight.w400,
        ),
      );

  // Responsive floating action button theme
  static FloatingActionButtonThemeData get floatingActionButtonTheme =>
      FloatingActionButtonThemeData(
        sizeConstraints: BoxConstraints.tightFor(
          width: ResponsiveUtils.buttonHeightLarge,
          height: ResponsiveUtils.buttonHeightLarge,
        ),
      );
}
