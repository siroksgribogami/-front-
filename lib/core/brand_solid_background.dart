import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Сплошной фон бренда #325D3C (без градиента).
class BrandSolidBackground extends StatelessWidget {
  const BrandSolidBackground({
    super.key,
    required this.child,
    this.color,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? AppTheme.primaryColor,
      child: child,
    );
  }
}
