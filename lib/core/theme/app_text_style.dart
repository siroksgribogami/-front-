import 'package:flutter/material.dart';

const _kGropledFontFamily = 'Gropled';

// Шрифт Gropled с исправленными метриками (ascent=830, descent=-218, USE_TYPO_METRICS=true).
// Flutter теперь правильно выравнивает текст без каких-либо костылей.
const kAppTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

class AppTextStyle {
  AppTextStyle._();

  static const String fontFamily = _kGropledFontFamily;
  static const double defaultHeight = 1.0;
  static const TextLeadingDistribution defaultLeadingDistribution =
      TextLeadingDistribution.even;

  static TextStyle gropled({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = const Color(0xFF2A3A2C),
    double? letterSpacing,
    double height = defaultHeight,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      leadingDistribution: defaultLeadingDistribution,
      decoration: decoration,
    );
  }

  static TextStyle display({
    Color color = Colors.white,
    double fontSize = 80,
    FontWeight fontWeight = FontWeight.w700,
    double? letterSpacing,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing ?? -2.0,
      );

  static TextStyle h1({
    Color color = const Color(0xFF2A3A2C),
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle h2({
    Color color = const Color(0xFF2A3A2C),
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle h3({
    Color color = const Color(0xFF2A3A2C),
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle button({
    Color color = const Color(0xFF6C8671),
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w600,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle caption({
    Color color = const Color(0xFF2A3A2C),
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.3,
      );

  static TextStyle tagline({
    Color color = Colors.white,
    double fontSize = 14,
    double letterSpacing = 3.0,
    FontWeight fontWeight = FontWeight.w400,
  }) => gropled(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textHeightBehavior: kAppTextHeightBehavior,
    );
  }
}
