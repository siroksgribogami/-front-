import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/brand_colors.dart';

/// Семантическая палитра маркетплейса Приделе (брендбук).
class MarketplaceColors {
  MarketplaceColors._();

  static const double contentMaxWidth = 520;

  static const Color background = BrandColors.canvas;
  static const Color card = BrandColors.milk;
  static const Color lightSurface = BrandColors.linen;
  static const Color lightBlueTint = BrandColors.linen;
  static const Color accentWarmBg = BrandColors.sandstone;

  static const Color bluePrimary = BrandColors.needles;
  static const Color blueSaturated = BrandColors.needlesDeep;
  static const Color blueDark = BrandColors.needlesBor;
  static const Color blueDeep = BrandColors.needlesDeep;

  // g100 — бледно-зелёный, фон чипов, статус-пилюль и т.д.
  static const Color paleSurface = BrandColors.needlesPale;

  /// Clay — один главный CTA на экран (отправка, 3D).
  static const Color ctaOrange = BrandColors.clay;
  static const Color clayAccent = BrandColors.clay;

  static const Color gold = BrandColors.gilded;

  /// Структурный зелёный (кнопки, выбранные чипы).
  static const Color aiTurquoise = BrandColors.needles;

  static const Color successService = BrandColors.needles;
  static const Color statusDeclined = BrandColors.surik;

  static const Color textOnDark = BrandColors.onNeedles;
  static const Color textMuted = Color(0xFF5C6B62);
  static const Color textPrimary = BrandColors.tar;
  static const Color textSecondary = Color(0xFF3D4A42);

  static const Color accent = clayAccent;
  static const Color turquoise = aiTurquoise;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundFor(BuildContext context) =>
      isDark(context) ? AppTheme.darkBackground : background;

  static Color cardFor(BuildContext context) =>
      isDark(context) ? AppTheme.darkCard : card;

  static Color surfaceFor(BuildContext context) =>
      isDark(context) ? AppTheme.darkSurface : lightSurface;

  static Color textPrimaryFor(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextPrimary : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextSecondary : textSecondary;

  static Color textMutedFor(BuildContext context) =>
      isDark(context) ? AppTheme.darkTextHint : textMuted;

  static double horizontalPaddingFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 96;
    if (width >= 900) return 72;
    if (width >= 600) return 32;
    return BrandColors.screenPadding;
  }
}
