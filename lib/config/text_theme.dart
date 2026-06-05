import 'package:flutter/material.dart';
import '../core/theme/app_text_style.dart';

export '../core/theme/app_text_style.dart';

/// Базовый TextStyle для Pochaevsk (логотип, заголовки, кнопки бренда).
TextStyle pochaevsk({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  Color color = const Color(0xFF1A2820),
  double? letterSpacing,
  double? height,
}) {
  return AppTextStyle.pochaevsk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height ?? 1.15,
  );
}

@Deprecated('Use pochaevsk()')
TextStyle gropled({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  Color color = const Color(0xFF1A2820),
  double? letterSpacing,
  double? height,
}) =>
    pochaevsk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

/// Глобальный TextHeightBehavior — применяется на уровне MaterialApp.
const kPochaevskHeightBehavior = kAppTextHeightBehavior;

@Deprecated('Use kPochaevskHeightBehavior')
const kGropledHeightBehavior = kPochaevskHeightBehavior;
