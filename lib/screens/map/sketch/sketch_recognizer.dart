import 'dart:math' as math;
import 'dart:ui';

import 'sketch_geometry.dart';
import 'sketch_models.dart';

/// Распознаёт свободную обводку в «выпрямленный» полигон комнаты — как
/// shape-recognition при рисовании на планшете:
///  • прямые стены подтягиваются к горизонтали/вертикали и к сетке;
///  • явные диагонали (срезанные углы, эркеры) сохраняются;
///  • вершины привязываются к сетке, чтобы комнаты стыковались.
abstract final class SketchRecognizer {
  SketchRecognizer._();

  /// Минимальная сторона bbox (px) — отсекаем «царапины».
  static const double _minSide = 24;

  /// Порог «почти ось»: tan(~18°). Круче — оставляем диагональю (срез).
  static const double _axisTan = 0.32;

  /// Превратить штрих в комнату-полигон. null — если штрих слишком мелкий.
  static SketchRoom? recognize(
    SketchStroke stroke, {
    required double cell,
    String name = 'Комната',
  }) {
    final pts = stroke.points;
    if (pts.length < 3) return null;
    final b = stroke.bounds;
    if (b.width < _minSide && b.height < _minSide) return null;

    final diag = math.sqrt(b.width * b.width + b.height * b.height);
    if (diag < _minSide) return null;

    // Замыкаем контур и упрощаем.
    final closed = [...pts, pts.first];
    final tol = math.max(diag * 0.045, cell * 0.55);
    var corners = SketchGeometry.simplify(closed, tol);
    if (corners.length > 1 &&
        (corners.first - corners.last).distance < tol) {
      corners = corners.sublist(0, corners.length - 1);
    }

    // Слишком мало углов — трактуем как прямоугольник по bbox.
    if (corners.length < 3) {
      corners = [b.topLeft, b.topRight, b.bottomRight, b.bottomLeft];
    }

    // Привязка вершин к сетке.
    var poly = corners.map((p) => SketchGeometry.snapToGrid(p, cell)).toList();

    // Выпрямление почти-осевых стен (несколько проходов для схождения углов).
    for (var pass = 0; pass < 3; pass++) {
      final n = poly.length;
      for (var i = 0; i < n; i++) {
        final a = poly[i];
        final bb = poly[(i + 1) % n];
        final dx = bb.dx - a.dx;
        final dy = bb.dy - a.dy;
        final adx = dx.abs();
        final ady = dy.abs();
        if (adx < 0.01 && ady < 0.01) continue;
        if (adx >= ady) {
          if (ady <= adx * _axisTan) {
            final y = SketchGeometry.snapToGrid(
                    Offset(0, (a.dy + bb.dy) / 2), cell)
                .dy;
            poly[i] = Offset(a.dx, y);
            poly[(i + 1) % n] = Offset(bb.dx, y);
          }
        } else {
          if (adx <= ady * _axisTan) {
            final x = SketchGeometry.snapToGrid(
                    Offset((a.dx + bb.dx) / 2, 0), cell)
                .dx;
            poly[i] = Offset(x, a.dy);
            poly[(i + 1) % n] = Offset(x, bb.dy);
          }
        }
      }
    }

    poly = _cleanup(poly, cell);
    if (poly.length < 3) return null;

    final pb = SketchGeometry.bounds(poly);
    if (pb.width < _minSide || pb.height < _minSide) {
      // Совсем вырожденный контур — заменяем прямоугольником.
      poly = [
        SketchGeometry.snapToGrid(b.topLeft, cell),
        SketchGeometry.snapToGrid(b.topRight, cell),
        SketchGeometry.snapToGrid(b.bottomRight, cell),
        SketchGeometry.snapToGrid(b.bottomLeft, cell),
      ];
    }

    return SketchRoom(polygon: poly, name: name);
  }

  /// Убираем слипшиеся и коллинеарные вершины.
  static List<Offset> _cleanup(List<Offset> poly, double cell) {
    final dedup = <Offset>[];
    for (final p in poly) {
      if (dedup.isEmpty || (dedup.last - p).distance > cell * 0.4) {
        dedup.add(p);
      }
    }
    if (dedup.length > 1 &&
        (dedup.first - dedup.last).distance <= cell * 0.4) {
      dedup.removeLast();
    }
    if (dedup.length < 3) return dedup;

    final out = <Offset>[];
    final n = dedup.length;
    for (var i = 0; i < n; i++) {
      final prev = dedup[(i - 1 + n) % n];
      final cur = dedup[i];
      final next = dedup[(i + 1) % n];
      final v1 = cur - prev;
      final v2 = next - cur;
      final cross = v1.dx * v2.dy - v1.dy * v2.dx;
      final dot = v1.dx * v2.dx + v1.dy * v2.dy;
      // Коллинеарная вершина (почти прямая) — выкидываем.
      if (cross.abs() < cell * cell * 0.05 && dot > 0) continue;
      out.add(cur);
    }
    return out.length >= 3 ? out : dedup;
  }
}
