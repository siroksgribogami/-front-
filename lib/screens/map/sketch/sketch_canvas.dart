import 'package:flutter/material.dart';

import '../../../core/theme/marketplace_colors.dart';
import 'sketch_models.dart';

/// Canvas со свободным рисованием. Сторонние операции «выпрямления» делает
/// [SketchRectifier], этот виджет только собирает штрихи.
class SketchCanvas extends StatefulWidget {
  const SketchCanvas({
    super.key,
    required this.strokes,
    required this.onStrokesChanged,
    this.preview,
  });

  final List<SketchStroke> strokes;
  final ValueChanged<List<SketchStroke>> onStrokesChanged;

  /// Опциональный «превью»-план для отображения уже распознанных комнат
  /// (показываем поверх рукописных штрихов).
  final SketchPlan? preview;

  @override
  State<SketchCanvas> createState() => _SketchCanvasState();
}

class _SketchCanvasState extends State<SketchCanvas> {
  SketchStroke? _current;

  void _start(Offset p) {
    setState(() => _current = SketchStroke(points: [p]));
  }

  void _move(Offset p) {
    final cur = _current;
    if (cur == null) return;
    if (cur.points.isNotEmpty &&
        (cur.points.last - p).distanceSquared < 2.5) {
      return;
    }
    setState(() => cur.points.add(p));
  }

  void _end() {
    final cur = _current;
    if (cur == null) return;
    final next = [...widget.strokes, cur];
    setState(() => _current = null);
    widget.onStrokesChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final bgColor = isDark
        ? const Color(0xFF111316)
        : const Color(0xFFF5F1E8);
    final strokeColor =
        isDark ? Colors.white.withOpacity(0.92) : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _start(d.localPosition),
        onPanUpdate: (d) => _move(d.localPosition),
        onPanEnd: (_) => _end(),
        onPanCancel: _end,
        child: CustomPaint(
          painter: _SketchPainter(
            strokes: [
              ...widget.strokes,
              if (_current != null) _current!,
            ],
            preview: widget.preview,
            gridColor: gridColor,
            strokeColor: strokeColor,
            previewColor: MarketplaceColors.bluePrimary,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  _SketchPainter({
    required this.strokes,
    required this.preview,
    required this.gridColor,
    required this.strokeColor,
    required this.previewColor,
  });

  final List<SketchStroke> strokes;
  final SketchPlan? preview;
  final Color gridColor;
  final Color strokeColor;
  final Color previewColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    // Свободные штрихи пользователя.
    final pen = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      if (s.points.length < 2) continue;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, pen);
    }

    // Поверх — превью «выпрямленных» комнат.
    final p = preview;
    if (p == null) return;
    final fill = Paint()
      ..color = previewColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final wall = Paint()
      ..color = previewColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;

    for (final room in p.rooms) {
      final rrect = RRect.fromRectAndRadius(
        room.rect,
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, wall);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    const step = 32.0;
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter old) {
    return old.strokes != strokes ||
        old.preview != preview ||
        old.gridColor != gridColor ||
        old.strokeColor != strokeColor;
  }
}
