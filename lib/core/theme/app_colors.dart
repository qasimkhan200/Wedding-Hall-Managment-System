import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryLight = Color(0xFFF8BBD9);
  static const Color primaryDark = Color(0xFFC2185B);

  // Secondary Colors
  static const Color secondary = Color(0xFF9C27B0);
  static const Color secondaryLight = Color(0xFFE1BEE7);

  // Accent Colors
  static const Color accent = Color(0xFFFF5722);
  static const Color accentLight = Color(0xFFFFCCBC);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF0F0F0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textLight = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Order Status Colors
  static const Color pending = Color(0xFFFF9800);
  static const Color accepted = Color(0xFF2196F3);
  static const Color preparing = Color(0xFF9C27B0);
  static const Color pickedUp = Color(0xFF00BCD4);
  static const Color inTransit = Color(0xFF3F51B5);
  static const Color delivered = Color(0xFF4CAF50);
  static const Color cancelled = Color(0xFFF44336);

  // Category Colors
  static const Color categoryChairs = Color(0xFF795548);
  static const Color categoryCrockery = Color(0xFF607D8B);
  static const Color categoryIce = Color(0xFF00BCD4);
  static const Color categoryFuel = Color(0xFFFF5722);
  static const Color categoryDecor = Color(0xFFE91E63);
  static const Color categoryManpower = Color(0xFF673AB7);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
