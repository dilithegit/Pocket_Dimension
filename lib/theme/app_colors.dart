import 'package:flutter/material.dart';

/// Semantic color palette for Pocket Dimension.
class AppColors {
  AppColors._();

  // Primary semantic roles
  static const Color background = Color(0xFF101016);
  static const Color surface = Color(0xFF1B1B26);
  static const Color surfaceElevated = Color(0xFF242433);
  static const Color border = Color(0xFF2E2E40);

  // Typography / Ink colors
  static const Color inkPrimary = Color(0xFFE8E8F0);
  static const Color inkSecondary = Color(0xFFA0A0B8);
  static const Color inkMuted = Color(0xFF6E6E85);

  // Accent color (placeholder that can be dynamically derived per World Bible)
  static const Color accent = Color(0xFFFFD56B); // Parchment Gold default
  static const Color accentVariant = Color(0xFFD4A338);

  // Masquerade / Regional Suspicion color stops
  static const Color suspicionLow = Color(0xFF4CAF50);  // Calm green (0-30%)
  static const Color suspicionMid = Color(0xFFFF9800);  // Wary orange (31-69%)
  static const Color suspicionHigh = Color(0xFFF44336); // Alert red (70-100%)

  // Helper method to resolve suspicion color dynamically from heat level (0-100)
  static Color getSuspicionColor(int heatLevel) {
    if (heatLevel >= 70) return suspicionHigh;
    if (heatLevel >= 31) return suspicionMid;
    return suspicionLow;
  }
}
