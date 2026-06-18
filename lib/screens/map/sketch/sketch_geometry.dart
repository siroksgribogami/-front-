import 'dart:math' as math;
import 'dart:ui';

/// Геометрические помощники для полигонального рисовальщика плана.
abstract final class SketchGeometry {
  SketchGeometry._();

  /// Привязка точки к сетке с шагом [cell].
  static Offset snapToGrid(Offset p, double cell) =>
      Offset((p.dx / cell).roundToDouble() * cell,
          (p.dy / cell).roundToDouble() * cell);

  /// Площадь полигона (формула шнурков), px².
  static double area(List<Offset> poly) {
    if (poly.length < 3) return 0;
    var s = 0.0;
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      s += a.dx * b.dy - b.dx * a.dy;
    }
    return s.abs() / 2;
  }

  /// Bounding box полигона.
  static Rect bounds(List<Offset> poly) {
    if (poly.isEmpty) return Rect.zero;
    var minX = poly.first.dx, maxX = minX;
    var minY = poly.first.dy, maxY = minY;
    for (final p in poly) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static Offset centroid(List<Offset> poly) {
    if (poly.isEmpty) return Offset.zero;
    var cx = 0.0, cy = 0.0;
    for (final p in poly) {
      cx += p.dx;
      cy += p.dy;
    }
    return Offset(cx / poly.length, cy / poly.length);
  }

  /// Точка внутри полигона (ray casting).
  static bool contains(List<Offset> poly, Offset pt) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final pi = poly[i], pj = poly[j];
      final intersect = (pi.dy > pt.dy) != (pj.dy > pt.dy) &&
          pt.dx <
              (pj.dx - pi.dx) * (pt.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx;
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Множество занятых клеток сетки внутри полигона (ключ = "cx,cy").
  /// Используется для проверки перекрытия комнат без полигональной булевой
  /// логики: комнаты «слипаются» стык-в-стык, но не делят клетки.
  static Set<int> occupiedCells(List<Offset> poly, double cell, int gridW) {
    final cells = <int>{};
    if (poly.length < 3) return cells;
    final b = bounds(poly);
    final x0 = (b.left / cell).floor();
    final x1 = (b.right / cell).ceil();
    final y0 = (b.top / cell).floor();
    final y1 = (b.bottom / cell).ceil();
    for (var cy = y0; cy < y1; cy++) {
      for (var cx = x0; cx < x1; cx++) {
        final center = Offset((cx + 0.5) * cell, (cy + 0.5) * cell);
        if (contains(poly, center)) {
          cells.add(cy * gridW + cx);
        }
      }
    }
    return cells;
  }

  /// Упрощение полилинии (Ramer–Douglas–Peucker).
  static List<Offset> simplify(List<Offset> pts, double tolerance) {
    if (pts.length < 3) return List.of(pts);
    var maxDist = 0.0;
    var index = 0;
    final end = pts.length - 1;
    for (var i = 1; i < end; i++) {
      final d = _perpDistance(pts[i], pts.first, pts[end]);
      if (d > maxDist) {
        maxDist = d;
        index = i;
      }
    }
    if (maxDist > tolerance) {
      final left = simplify(pts.sublist(0, index + 1), tolerance);
      final right = simplify(pts.sublist(index), tolerance);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [pts.first, pts.last];
  }

  static double _perpDistance(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (len * len);
    final proj = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - proj).distance;
  }
}
