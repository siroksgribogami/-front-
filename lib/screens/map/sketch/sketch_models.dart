import 'dart:math' as math;
import 'dart:ui';

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

  /// Длина обводки (px) — отсекаем «точки» и слишком короткие штрихи.
  double get pathLength {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  /// Замкнут ли штрих: расстояние от конца до начала < 25% от диагонали bbox.
  bool get isClosed {
    if (points.length < 4) return false;
    final b = bounds;
    final diag = math.sqrt(b.width * b.width + b.height * b.height);
    if (diag < 24) return false;
    final endToStart = (points.first - points.last).distance;
    return endToStart < diag * 0.30;
  }
}

/// Прямоугольная комната — результат «спрямления» свободного штриха.
class RectifiedRoom {
  RectifiedRoom({
    required this.rect,
    this.name = 'Комната',
  });

  final Rect rect;
  String name;

  RectifiedRoom copyWith({Rect? rect, String? name}) =>
      RectifiedRoom(rect: rect ?? this.rect, name: name ?? this.name);
}

/// Результат «выпрямления» эскиза.
class SketchPlan {
  SketchPlan({required this.rooms, required this.canvasSize});

  final List<RectifiedRoom> rooms;
  final Size canvasSize;

  /// Общий bbox всех комнат в координатах canvas.
  Rect get bounds {
    if (rooms.isEmpty) return Rect.zero;
    var r = rooms.first.rect;
    for (final room in rooms.skip(1)) {
      r = r.expandToInclude(room.rect);
    }
    return r;
  }
}
