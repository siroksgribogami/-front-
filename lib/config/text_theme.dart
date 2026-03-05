import 'package:flutter/material.dart';
import '../core/theme/app_text_style.dart';

export '../core/theme/app_text_style.dart';

/// Базовый TextStyle для Gropled с исправленными вертикальными метриками.
/// Убирает лишнее пространство сверху/снизу букв, которое Gropled добавляет.
TextStyle gropled({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  Color color = const Color(0xFF2A3A2C),
  double? letterSpacing,
  double? height,
}) {
  return AppTextStyle.gropled(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height ?? 1.15,
  );
}

/// Глобальный TextHeightBehavior — применяется на уровне MaterialApp.
/// Аналог Figma «Vertical trim → Cap height».
const kGropledHeightBehavior = kAppTextHeightBehavior;
