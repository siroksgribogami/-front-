import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Семантическая палитра ARTkhaus для первого (зелёного) дизайна.
class MarketplaceColors {
  MarketplaceColors._();

  /// Макс. ширина основной колонки контента (как [PostRegisterSurveyScreen]).
  static const double contentMaxWidth = 520;

  // --- Фоны ---
  static const Color background = Color(0xFFF7F3EC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEDE8E0);
  static const Color lightBlueTint = Color(0xFFC6D9CE);
  static const Color accentWarmBg = Color(0xFFFFF4E6);

  // --- Брендовая шкала первого дизайна (шалфей) ---
  static const Color bluePrimary = Color(0xFF659171);
  static const Color blueSaturated = Color(0xFF547A62);
  static const Color blueDark = Color(0xFF3F5F4B);
  static const Color blueDeep = Color(0xFF2A3A2C);

  /// CTA: терракотовый акцент.
  static const Color ctaOrange = Color(0xFFD4956A);

  static const Color gold = Color(0xFFE8B931);

  /// Акцент для AI/подсказок.
  static const Color aiTurquoise = Color(0xFF80B490);

  /// Успешные сервисные статусы.
  static const Color successService = Color(0xFF659171);

  /// Отказ / ошибка по сделке.
  static const Color statusDeclined = Color(0xFFB87070);

  // --- Текст ---
  static const Color textOnDark = Color(0xFF2A3A2C);
  static const Color textMuted = Color(0xFF506A58);

  /// Основной текст на тёмном фоне маркетплейса.
  static const Color textPrimary = textOnDark;

  /// Вторичный текст (по гайду — приглушённый сине-серый).
  static const Color textSecondary = textMuted;

  // Совместимость с ранним кодом (accent / turquoise).
  static const Color accent = ctaOrange;
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

  /// Респонсивный горизонтальный отступ от краёв контентной области
  /// (используется во всех экранах маркетплейса для согласованности).
  static double horizontalPaddingFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 96;
    if (width >= 900) return 72;
    if (width >= 600) return 32;
    return 16;
  }
}
