import 'package:flutter/material.dart';

/// Официальная палитра брендбука «При деле» (ред. 1.0).
/// Правило 60-30-10: холст / хвоя / глина (один clay-CTA на экран).
abstract final class BrandColors {
  // --- Холст (60%) ---
  static const Color canvas = Color(0xFFEFEBE0);
  static const Color milk = Color(0xFFFAF7F0);
  static const Color linen = Color(0xFFE7E1D2);

  // --- Хвоя (30%) ---
  static const Color needles = Color(0xFF325D3C);       // g600 #325D3C
  static const Color needlesDeep = Color(0xFF16301D);   // g900 #16301D
  static const Color needlesBor = Color(0xFF1E3A26);    // g800 #1E3A26
  static const Color needlesDim = Color(0xFF264C2F);    // g700 #264C2F
  static const Color needlesLight = Color(0xFF4C7A55);  // g500 #4C7A55
  static const Color needlesPale = Color(0xFFE3EBDC);   // g100 #E3EBDC

  // --- Глина — акцент 10%, не заливать большие площади ---
  static const Color clay = Color(0xFFBB5C45);
  static const Color surik = Color(0xFF9A4738);
  static const Color dawn = Color(0xFFD28B75);
  static const Color sandstone = Color(0xFFEBD8D1);

  // --- Текст и редкий золотой штрих ---
  static const Color tar = Color(0xFF1A2820);
  static const Color inkSoft = Color(0xFF5B6A5E);
  static const Color inkFaint = Color(0xFF8A968C);
  static const Color needlesDark = Color(0xFF264C2F);
  static const Color gilded = Color(0xFFC29A4A);

  static const Color onNeedles = Color(0xFFFAF7F0);
  static const Color onClay = Color(0xFFFAF7F0);

  static const Color borderSubtle = Color(0xFFD4CEC0);
  static const Color chipBorder = Color(0xFFC8C2B4);

  static const double radiusCard = 16;
  static const double radiusButton = 14;
  static const double radiusChip = 12;
  static const double screenPadding = 16;
}
