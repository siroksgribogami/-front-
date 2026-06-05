import 'package:flutter/material.dart';

import '../../../config/brand_colors.dart';
/// Зелёная «сцена» — чертёж, сетка, wireframe, метрики (режим A брендбука).
class ForemanSceneWorkspace extends StatelessWidget {
  const ForemanSceneWorkspace({
    super.key,
    this.areaM2,
    this.roomsCount,
    this.estimateLabel,
    this.onExpand,
  });

  final double? areaM2;
  final int? roomsCount;
  final String? estimateLabel;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandColors.needles,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _BlueprintGridPainter()),
          Positioned(
            top: 12,
            left: BrandColors.screenPadding,
            child: _MonoLabel('UNITY • ЧЕРНОВИК'),
          ),
          Positioned(
            top: 12,
            right: BrandColors.screenPadding,
            child: _MonoLabel('СБОР ДАННЫХ'),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: CustomPaint(
                size: const Size(200, 140),
                painter: _RoomWireframePainter(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MetricsBar(
              areaM2: areaM2,
              roomsCount: roomsCount,
              estimateLabel: estimateLabel,
            ),
          ),
          if (onExpand != null)
            Positioned(
              right: BrandColors.screenPadding,
              bottom: 52,
              child: TextButton(
                onPressed: onExpand,
                style: TextButton.styleFrom(
                  foregroundColor: BrandColors.onNeedles.withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  'Развернуть',
                  style: _monoStyle(11).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: BrandColors.onNeedles.withOpacity(0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonoLabel extends StatelessWidget {
  const _MonoLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _monoStyle(10));
  }
}

TextStyle _monoStyle(double size) => TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      color: BrandColors.onNeedles.withOpacity(0.72),
    );

class _MetricsBar extends StatelessWidget {
  const _MetricsBar({
    this.areaM2,
    this.roomsCount,
    this.estimateLabel,
  });

  final double? areaM2;
  final int? roomsCount;
  final String? estimateLabel;

  @override
  Widget build(BuildContext context) {
    final area = areaM2 != null ? areaM2!.toStringAsFixed(0) : '—';
    final rooms = roomsCount?.toString() ?? '0';
    final est = estimateLabel ?? '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: BrandColors.onNeedles.withOpacity(0.12)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _metric('ПЛОЩАДЬ', '$area м²')),
          _divider(),
          Expanded(child: _metric('КОМНАТ', rooms)),
          _divider(),
          Expanded(child: _metric('СМЕТА', est)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: BrandColors.onNeedles.withOpacity(0.15),
      );

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _monoStyle(9)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: BrandColors.onNeedles,
            ),
          ),
        ],
      );
}

class _BlueprintGridPainter extends CustomPainter {
  const _BlueprintGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.onNeedles.withOpacity(0.08)
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoomWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = BrandColors.gilded.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final notch = Paint()
      ..color = BrandColors.onNeedles.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.18, size.width * 0.76, size.height * 0.64),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, stroke);

    const notchLen = 14.0;
    final r = rect.outerRect;
    _cornerNotch(canvas, notch, r.topLeft, notchLen, true, true);
    _cornerNotch(canvas, notch, r.topRight, notchLen, false, true);
    _cornerNotch(canvas, notch, r.bottomLeft, notchLen, true, false);
    _cornerNotch(canvas, notch, r.bottomRight, notchLen, false, false);

    final inner = Paint()
      ..color = BrandColors.onNeedles.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(r.left + r.width * 0.35, r.top),
      Offset(r.left + r.width * 0.35, r.bottom),
      inner,
    );
    canvas.drawLine(
      Offset(r.left, r.top + r.height * 0.55),
      Offset(r.right, r.top + r.height * 0.55),
      inner,
    );
  }

  void _cornerNotch(
    Canvas canvas,
    Paint paint,
    Offset corner,
    double len,
    bool left,
    bool top,
  ) {
    if (left && top) {
      canvas.drawLine(corner, corner + Offset(len, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, len), paint);
    } else if (!left && top) {
      canvas.drawLine(corner, corner + Offset(-len, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, len), paint);
    } else if (left && !top) {
      canvas.drawLine(corner, corner + Offset(len, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, -len), paint);
    } else {
      canvas.drawLine(corner, corner + Offset(-len, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, -len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Шапка сплит-экрана: лого-зона + чипы ПРИДЕЛЕ / ИИ-СМЕТА.
class ForemanSplitAppBar extends StatelessWidget {
  const ForemanSplitAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.milk,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BrandColors.needles,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_work_outlined,
                    color: BrandColors.onNeedles, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: BrandColors.tar,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(text: 'ИИ-'),
                          TextSpan(
                            text: 'прораб',
                            style: TextStyle(color: BrandColors.clay),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'формирует карту',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: BrandColors.tar.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              _outlineChip('ПРИДЕЛЕ'),
              const SizedBox(width: 6),
              _outlineChip('ИИ-СМЕТА'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlineChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: BrandColors.needles.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: _monoStyle(9).copyWith(
            color: BrandColors.needles,
            letterSpacing: 0.8,
          ),
        ),
      );
}
