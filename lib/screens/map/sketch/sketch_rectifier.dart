import 'dart:ui';

import 'sketch_models.dart';

/// «Выпрямление» свободных штрихов в осевые прямоугольники.
///
/// Алгоритм (упрощённый, без CV):
/// 1. Замкнутый штрих → axis-aligned bbox.
/// 2. Незамкнутый, но длинный и c заметным bbox — тоже превращаем в bbox
///    (как «обвёл прямоугольник одной линией, не дойдя обратно»).
/// 3. Если прямоугольники почти касаются по стороне (зазор ≤ snapPx) —
///    подвигаем границы так, чтобы стены совпали (как делает Samsung Map Mode).
abstract final class SketchRectifier {
  SketchRectifier._();

  /// Минимальные стороны прямоугольника в px на canvas — отсеиваем «царапины».
  static const double _minSide = 28;

  /// Зазор, при котором стены «слипаются».
  static const double _snapPx = 18;

  static SketchPlan rectify(List<SketchStroke> strokes, Size canvasSize) {
    final rooms = <RectifiedRoom>[];

    for (final stroke in strokes) {
      if (stroke.points.length < 3) continue;
      if (stroke.pathLength < _minSide) continue;
      final b = stroke.bounds;
      if (b.width < _minSide || b.height < _minSide) continue;

      // Принимаем как комнату и замкнутые, и явные «обводы» (длина пути
      // заметно больше периметра bbox только при хаотичных каракулях).
      final perimeter = 2 * (b.width + b.height);
      if (!stroke.isClosed && stroke.pathLength > perimeter * 3) {
        continue;
      }

      // Слегка «затягиваем» прямоугольник внутрь — пользователь обычно
      // рисует чуть «расплывшийся» контур, наружные пики срезаем.
      final shrink = (stroke.pathLength / perimeter).clamp(1.0, 1.4) - 1.0;
      final dx = b.width * 0.03 * shrink;
      final dy = b.height * 0.03 * shrink;
      final tight = Rect.fromLTRB(
        b.left + dx,
        b.top + dy,
        b.right - dx,
        b.bottom - dy,
      );

      rooms.add(RectifiedRoom(rect: tight, name: _autoName(rooms.length)));
    }

    final snapped = _snapEdges(rooms);
    return SketchPlan(rooms: snapped, canvasSize: canvasSize);
  }

  static String _autoName(int index) {
    const names = ['Гостиная', 'Кухня', 'Спальня', 'Ванная', 'Прихожая', 'Кабинет', 'Балкон'];
    if (index < names.length) return names[index];
    return 'Комната ${index + 1}';
  }

  /// Притягиваем близкие стены (≤ snapPx) друг к другу, чтобы комнаты
  /// составили целостный план без щелей.
  static List<RectifiedRoom> _snapEdges(List<RectifiedRoom> input) {
    if (input.length < 2) return input;
    final rects = input.map((r) => r.rect).toList();

    for (var i = 0; i < rects.length; i++) {
      for (var j = 0; j < rects.length; j++) {
        if (i == j) continue;
        final a = rects[i];
        final b = rects[j];

        // Притягиваем left/right
        for (final aEdge in <double>[a.left, a.right]) {
          for (final bEdge in <double>[b.left, b.right]) {
            if ((aEdge - bEdge).abs() < _snapPx) {
              rects[i] = _shiftHorizontalEdge(rects[i], aEdge, bEdge);
            }
          }
        }
        // Притягиваем top/bottom
        for (final aEdge in <double>[a.top, a.bottom]) {
          for (final bEdge in <double>[b.top, b.bottom]) {
            if ((aEdge - bEdge).abs() < _snapPx) {
              rects[i] = _shiftVerticalEdge(rects[i], aEdge, bEdge);
            }
          }
        }
      }
    }

    return [
      for (var i = 0; i < input.length; i++) input[i].copyWith(rect: rects[i]),
    ];
  }

  static Rect _shiftHorizontalEdge(Rect r, double oldX, double newX) {
    if ((r.left - oldX).abs() < 0.5) {
      return Rect.fromLTRB(newX, r.top, r.right, r.bottom);
    }
    if ((r.right - oldX).abs() < 0.5) {
      return Rect.fromLTRB(r.left, r.top, newX, r.bottom);
    }
    return r;
  }

  static Rect _shiftVerticalEdge(Rect r, double oldY, double newY) {
    if ((r.top - oldY).abs() < 0.5) {
      return Rect.fromLTRB(r.left, newY, r.right, r.bottom);
    }
    if ((r.bottom - oldY).abs() < 0.5) {
      return Rect.fromLTRB(r.left, r.top, r.right, newY);
    }
    return r;
  }
}
