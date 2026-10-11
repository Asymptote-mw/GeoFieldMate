import 'package:flutter/material.dart';

/// App color palette inspired by geological and earth tones
class AppColors {
  // Primary colors - Earth tones
  static const Color primaryGreen = Color(0xFF4A7C59);
  static const Color secondaryBrown = Color(0xFF8B7355);
  static const Color accentYellow = Color(0xFFD4A574);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F0);
  static const Color backgroundDark = Color(0xFF2C2C2C);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF3A3A3A);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Rock type colors (for visual categorization)
  static const Color igneous = Color(0xFFD32F2F);
  static const Color sedimentary = Color(0xFFFFB74D);
  static const Color metamorphic = Color(0xFF7B1FA2);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF42A5F5);

  // Gradient colors
  static const LinearGradient earthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, secondaryBrown],
  );
}
