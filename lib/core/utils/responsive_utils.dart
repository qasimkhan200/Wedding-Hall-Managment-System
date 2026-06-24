import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveUtils {
  // Screen breakpoints
  static bool isTablet(BuildContext context) => ScreenUtil().screenWidth > 600;
  static bool isMobile(BuildContext context) => ScreenUtil().screenWidth <= 600;
  static bool isLargeScreen(BuildContext context) =>
      ScreenUtil().screenWidth > 900;

  static double get screenWidth => ScreenUtil().screenWidth;
  static double get screenHeight => ScreenUtil().screenHeight;

  // Responsive spacing
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  // Responsive heights
  static double get xsHeight => 4.h;
  static double get smHeight => 8.h;
  static double get mdHeight => 16.h;
  static double get lgHeight => 24.h;
  static double get xlHeight => 32.h;
  static double get xxlHeight => 48.h;

  // Responsive font sizes
  static double get caption => 12.sp;
  static double get body2 => 14.sp;
  static double get body1 => 16.sp;
  static double get subtitle2 => 18.sp;
  static double get subtitle1 => 20.sp;
  static double get headline6 => 22.sp;
  static double get headline5 => 24.sp;
  static double get headline4 => 28.sp;
  static double get headline3 => 32.sp;
  static double get headline2 => 36.sp;
  static double get headline1 => 40.sp;

  // Responsive icon sizes
  static double get iconXs => 16.w;
  static double get iconSm => 20.w;
  static double get iconMd => 24.w;
  static double get iconLg => 32.w;
  static double get iconXl => 40.w;

  // Responsive border radius
  static double get radiusXs => 4.r;
  static double get radiusSm => 8.r;
  static double get radiusMd => 12.r;
  static double get radiusLg => 16.r;
  static double get radiusXl => 24.r;

  // Responsive card dimensions
  static double get cardHeight => 120.h;
  static double get cardHeightLarge => 180.h;
  static double get cardWidth => 160.w;
  static double get cardWidthLarge => 200.w;

  // Responsive button dimensions
  static double get buttonHeight => 48.h;
  static double get buttonHeightSmall => 36.h;
  static double get buttonHeightLarge => 56.h;

  // Grid responsive columns
  static int getGridColumns(BuildContext context) {
    if (isLargeScreen(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  // Responsive padding
  static EdgeInsets get paddingXs => EdgeInsets.all(xs);
  static EdgeInsets get paddingSm => EdgeInsets.all(sm);
  static EdgeInsets get paddingMd => EdgeInsets.all(md);
  static EdgeInsets get paddingLg => EdgeInsets.all(lg);
  static EdgeInsets get paddingXl => EdgeInsets.all(xl);

  // Responsive horizontal padding
  static EdgeInsets get paddingHorizontalXs =>
      EdgeInsets.symmetric(horizontal: xs);
  static EdgeInsets get paddingHorizontalSm =>
      EdgeInsets.symmetric(horizontal: sm);
  static EdgeInsets get paddingHorizontalMd =>
      EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets get paddingHorizontalLg =>
      EdgeInsets.symmetric(horizontal: lg);
  static EdgeInsets get paddingHorizontalXl =>
      EdgeInsets.symmetric(horizontal: xl);

  // Responsive vertical padding
  static EdgeInsets get paddingVerticalXs =>
      EdgeInsets.symmetric(vertical: xsHeight);
  static EdgeInsets get paddingVerticalSm =>
      EdgeInsets.symmetric(vertical: smHeight);
  static EdgeInsets get paddingVerticalMd =>
      EdgeInsets.symmetric(vertical: mdHeight);
  static EdgeInsets get paddingVerticalLg =>
      EdgeInsets.symmetric(vertical: lgHeight);
  static EdgeInsets get paddingVerticalXl =>
      EdgeInsets.symmetric(vertical: xlHeight);

  // Safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top + sm,
      bottom: mediaQuery.padding.bottom + sm,
      left: sm,
      right: sm,
    );
  }

  // Responsive container constraints
  static BoxConstraints get cardConstraints => BoxConstraints(
        minHeight: cardHeight,
        maxWidth: double.infinity,
      );

  static BoxConstraints get buttonConstraints => BoxConstraints(
        minHeight: buttonHeight,
        maxWidth: double.infinity,
      );
}
