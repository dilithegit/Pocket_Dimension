import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale using Serif for narration & lore, and Sans-serif for UI chrome.
class AppTypography {
  AppTypography._();

  static const String serifFontFamily = 'Georgia';
  static const String sansFontFamily = 'Roboto';

  // Serif typography for narration, story titles, character names & lore prose
  static const TextStyle narrationDisplay = TextStyle(
    fontFamily: serifFontFamily,
    fontFamilyFallback: ['serif'],
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: AppColors.inkPrimary,
  );

  static const TextStyle narrationBody = TextStyle(
    fontFamily: serifFontFamily,
    fontFamilyFallback: ['serif'],
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.6,
    color: AppColors.inkPrimary,
  );

  static const TextStyle loreTitle = TextStyle(
    fontFamily: serifFontFamily,
    fontFamilyFallback: ['serif'],
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.accent,
  );

  // Sans-Serif typography for UI chrome, controls, input fields, labels & stats
  static const TextStyle uiHeader = TextStyle(
    fontFamily: sansFontFamily,
    fontFamilyFallback: ['sans-serif'],
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: AppColors.inkPrimary,
  );

  static const TextStyle uiBody = TextStyle(
    fontFamily: sansFontFamily,
    fontFamilyFallback: ['sans-serif'],
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.inkPrimary,
  );

  static const TextStyle uiLabel = TextStyle(
    fontFamily: sansFontFamily,
    fontFamilyFallback: ['sans-serif'],
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSecondary,
  );

  static const TextStyle uiCaption = TextStyle(
    fontFamily: sansFontFamily,
    fontFamilyFallback: ['sans-serif'],
    fontSize: 11.0,
    fontWeight: FontWeight.normal,
    color: AppColors.inkMuted,
  );
}
