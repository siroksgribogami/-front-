import 'dart:math' as math;
import 'dart:ui';

import 'sketch_geometry.dart';

/// Один свободный мазок пользователя — массив точек в координатах canvas (px).
class SketchStroke {
  SketchStroke({List<Offset>? points}) : points = points ?? <Offset>[];

  final List<Offset> points;

  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx, maxX = minX;
    double minY = points.first.dy, maxY = minY;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double get pathLength {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }
}

var _roomCounter = 0;

/// Комната как полигон вершин (px на canvas). Может быть прямоугольной,
/// Г-образной или со срезанными (диагональными) углами.
class SketchRoom {
  SketchRoom({
    required this.polygon,
    this.name = 'Комната',
    String? id,
  }) : id = id ?? 'room_${_roomCounter++}';

  /// Замкнутый контур без повторения первой точки в конце.
  List<Offset> polygon;
  String name;
  final String id;

  Rect get bounds => SketchGeometry.bounds(polygon);
  double get areaPx => SketchGeometry.area(polygon);
  Offset get centroid => SketchGeometry.centroid(polygon);

  /// Совместимость со старым кодом: прямоугольник = bbox.
  Rect get rect => bounds;

  bool get isRect => polygon.length == 4;

  SketchRoom copyWith({List<Offset>? polygon, String? name}) => SketchRoom(
        polygon: polygon ?? List.of(this.polygon),
        name: name ?? this.name,
        id: id,
      );

  SketchRoom translated(Offset delta) => copyWith(
        polygon: polygon.map((p) => p + delta).toList(),
      );
}

/// План этажа — набор полигональных комнат.
class SketchPlan {
  SketchPlan({required this.rooms, required this.canvasSize});

  final List<SketchRoom> rooms;
  final Size canvasSize;

  Rect get bounds {
    if (rooms.isEmpty) return Rect.zero;
    var r = rooms.first.bounds;
    for (final room in rooms.skip(1)) {
      r = r.expandToInclude(room.bounds);
    }
    return r;
  }

  static String autoName(int index) {
    const names = [
      'Гостиная',
      'Кухня',
      'Спальня',
      'Ванная',
      'Прихожая',
      'Кабинет',
      'Детская',
      'Балкон',
    ];
    if (index < names.length) return names[index];
    return 'Комната ${index + 1}';
  }
}

/// Прямоугольная комната — оставлено для обратной совместимости.
class RectifiedRoom {
  RectifiedRoom({required this.rect, this.name = 'Комната'});
  final Rect rect;
  String name;

  List<Offset> get polygon => [
        rect.topLeft,
        rect.topRight,
        rect.bottomRight,
        rect.bottomLeft,
      ];

  double get diagonal =>
      math.sqrt(rect.width * rect.width + rect.height * rect.height);
}
