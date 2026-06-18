import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/brand_colors.dart';

/// Рантайм-палитра бренда: отдаёт светлый или тёмный цвет в зависимости от
/// активной темы. Значение [isDark] выставляется в `main.dart` перед сборкой
/// дерева (при смене темы `MaterialApp` пересобирает всё дерево, поэтому чтение
/// геттеров во время build всегда актуально).
///
/// Использовать вместо жёстких `BrandColors.canvas/milk/tar/linen/...` в местах,
/// где раньше цвет был зашит только под светлую тему.
abstract final class BrandRuntime {
  static bool isDark = false;

  // --- Поверхности (60%) ---
  /// Фон Scaffold (холст / уголь).
  static Color get canvas =>
      isDark ? AppTheme.darkBackground : BrandColors.canvas;

  /// Карточка / приподнятая поверхность (молоко / тёмная карточка).
  static Color get card => isDark ? AppTheme.darkCard : BrandColors.milk;

  /// Вторичная поверхность (лён / тёмная подложка).
  static Color get surface =>
      isDark ? AppTheme.darkSurface : BrandColors.linen;

  // --- Текст ---
  static Color get ink =>
      isDark ? AppTheme.darkTextPrimary : BrandColors.tar;
  static Color get inkSoft =>
      isDark ? AppTheme.darkTextSecondary : BrandColors.inkSoft;
  static Color get inkFaint =>
      isDark ? AppTheme.darkTextHint : BrandColors.inkFaint;

  // --- Границы ---
  static Color get border =>
      isDark ? AppTheme.darkBorder : BrandColors.borderSubtle;
  static Color get borderStrong =>
      isDark ? AppTheme.darkBorder : BrandColors.chipBorder;

  // --- Акценты ---
  /// Зелёный как ТЕКСТ/иконки/цифры: в тёмной теме светлеет до шалфея,
  /// иначе тёмно-зелёный сливается с тёмными карточками.
  static Color get needles =>
      isDark ? const Color(0xFF8FB089) : BrandColors.needles;

  /// Зелёный как ЗАЛИВКА (кнопки, чипы, плашки): всегда брендовый тёмный,
  /// чтобы белый текст поверх оставался контрастным.
  static Color get needlesFill => BrandColors.needles;

  static Color get clay => BrandColors.clay;

  /// Бледно-зелёная заливка чипов/баннеров (g100 → тёмный зелёный).
  static Color get needlesPale =>
      isDark ? const Color(0xFF20302A) : BrandColors.needlesPale;

  /// Иммерсивный бренд-фон онбординга (зелёный → углублённый).
  static Color get immersive =>
      isDark ? AppTheme.darkBackground : BrandColors.needles;
}
