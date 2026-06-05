import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';

const _kPochaevskFontFamily = 'Pochaevsk';

// Display-шрифт Pochaevsk (OFL, Slavonic Computing Initiative).
const kAppTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

class AppTextStyle {
  AppTextStyle._();

  static const String fontFamily = _kPochaevskFontFamily;

  /// Интерфейсный шрифт (брендбук: всё кроме крупных display).
  static const String uiFontFamily = 'Inter';
  static const double defaultHeight = 1.0;
  static const TextLeadingDistribution defaultLeadingDistribution =
      TextLeadingDistribution.even;

  static TextStyle pochaevsk({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = BrandColors.tar,
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

  @Deprecated('Use pochaevsk()')
  static TextStyle gropled({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = BrandColors.tar,
    double? letterSpacing,
    double height = defaultHeight,
    TextDecoration? decoration,
  }) =>
      pochaevsk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );

  static TextStyle display({
    Color color = Colors.white,
    double fontSize = 80,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
  }) =>
      pochaevsk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing ?? -2.0,
      );

  static TextStyle h1({
    Color color = BrandColors.tar,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      pochaevsk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle h2({
    Color color = BrandColors.tar,
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      pochaevsk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle h3({
    Color color = BrandColors.tar,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      pochaevsk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle button({
    Color color = BrandColors.needles,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: defaultHeight,
        leadingDistribution: defaultLeadingDistribution,
      );

  static TextStyle inter({
    Color color = BrandColors.tar,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    List<FontFeature>? fontFeatures,
  }) =>
      TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.35,
        leadingDistribution: defaultLeadingDistribution,
        fontFeatures: fontFeatures,
      );

  static TextStyle caption({
    Color color = BrandColors.tar,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      pochaevsk(
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
  }) =>
      pochaevsk(
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
