import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Фон бренда: градиент #0C371E → #325D3C (как на логотипе).
class BrandGradientBackground extends StatelessWidget {
  const BrandGradientBackground({
    super.key,
    required this.child,
    this.begin,
    this.end,
  });

  final Widget child;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.brandGradientDecoration(
        begin: begin ?? Alignment.topLeft,
        end: end ?? Alignment.bottomRight,
      ),
      child: child,
    );
  }
}
