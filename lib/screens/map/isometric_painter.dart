import 'package:flutter/material.dart';
import '../../models/room_layout.dart';
import '../../config/app_theme.dart';

// ============================================================
//  ИЗОМЕТРИЧЕСКИЙ РЕНДЕРЕР КОМНАТЫ (как в Sims)
// ============================================================

/// Математика изометрической проекции
class IsoProjection {
  /// Размер одной клетки (ширина в пикселях в iso-пространстве)
  final double tileW;
  /// Высота клетки в iso (обычно = tileW / 2)
  final double tileH;
  /// Отступ сверху (чтобы комната не прилипала к границе)
  final double offsetX;
  final double offsetY;

  const IsoProjection({
    this.tileW = 72.0,
    this.tileH = 36.0,
    required this.offsetX,
    required this.offsetY,
  });

  /// Клетка (gx, gy) → левая точка iso-ромба
  Offset toScreen(double gx, double gy) {
    final sx = (gx - gy) * (tileW / 2) + offsetX;
    final sy = (gx + gy) * (tileH / 2) + offsetY;
    return Offset(sx, sy);
  }

  /// Экранная точка → клетка (float)
  Offset toGrid(Offset screen) {
    final dx = screen.dx - offsetX;
    final dy = screen.dy - offsetY;
    final gx = (dx / (tileW / 2) + dy / (tileH / 2)) / 2;
    final gy = (dy / (tileH / 2) - dx / (tileW / 2)) / 2;
    return Offset(gx, gy);
  }

  /// Центр клетки (gx, gy)
  Offset centerOf(double gx, double gy) {
    return toScreen(gx + 0.5, gy + 0.5);
  }

  /// 4 вершины iso-ромба для клетки (gx, gy)
  List<Offset> tileVertices(double gx, double gy) {
    final top    = toScreen(gx,       gy);
    final right  = toScreen(gx + 1.0, gy);
    final bottom = toScreen(gx + 1.0, gy + 1.0);
    final left   = toScreen(gx,       gy + 1.0);
    return [top, right, bottom, left];
  }

  /// Левая стена (верт. ромб слева от тайла)
  List<Offset> leftWallVertices(double gx, double gy, double wallH) {
    final bl = toScreen(gx,       gy + 1.0);
    final br = toScreen(gx + 1.0, gy + 1.0);
    return [
      bl,
      br,
      Offset(br.dx, br.dy - wallH),
      Offset(bl.dx, bl.dy - wallH),
    ];
  }

  /// Правая стена
  List<Offset> rightWallVertices(double gx, double gy, double wallH) {
    final bl = toScreen(gx + 1.0, gy);
    final br = toScreen(gx + 1.0, gy + 1.0);
    return [
      bl,
      br,
      Offset(br.dx, br.dy - wallH),
      Offset(bl.dx, bl.dy - wallH),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
//  CustomPainter — рисует комнату целиком
// ─────────────────────────────────────────────────────────────

class IsometricRoomPainter extends CustomPainter {
  final RoomLayout room;
  final IsoProjection proj;
  final PlacedFurniture? selectedFurniture;
  final int? hoverX;
  final int? hoverY;
  final int? dragW;  // размер перетаскиваемого объекта
  final int? dragH;

  IsometricRoomPainter({
    required this.room,
    required this.proj,
    this.selectedFurniture,
    this.hoverX,
    this.hoverY,
    this.dragW,
    this.dragH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas);
    _drawWalls(canvas);
    _drawFurniture(canvas);
    _drawHoverHighlight(canvas);
    _drawGrid(canvas);
  }

  // --- ПОЛ ------------------------------------------------
  void _drawFloor(Canvas canvas) {
    final paint = Paint()..color = room.floorMaterial.color;
    final shadow = Paint()..color = Colors.black.withOpacity(0.06);

    for (int y = 0; y < room.gridHeight; y++) {
      for (int x = 0; x < room.gridWidth; x++) {
        final verts = proj.tileVertices(x.toDouble(), y.toDouble());
        _fillPolygon(canvas, verts, paint);
        // Тонкая сетка
        _strokePolygon(canvas, verts, shadow, strokeWidth: 0.5);
      }
    }
  }

  // --- СТЕНЫ -----------------------------------------------
  void _drawWalls(Canvas canvas) {
    const wallH = 40.0;
    final lightWall = Paint()..color = room.wallMaterial.color.withOpacity(0.85);
    final darkWall  = Paint()..color = room.wallMaterial.color.withOpacity(0.6);
    final outline   = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Левые стены (y=0 — вся полоса)
    for (int x = 0; x < room.gridWidth; x++) {
      final verts = proj.leftWallVertices(x.toDouble(), 0, wallH);
      _fillPolygon(canvas, verts, lightWall);
      _strokePolygon(canvas, verts, outline);
    }

    // Правые стены (x=0 — вся полоса)
    for (int y = 0; y < room.gridHeight; y++) {
      final verts = proj.rightWallVertices(0, y.toDouble(), wallH);
      _fillPolygon(canvas, verts, darkWall);
      _strokePolygon(canvas, verts, outline);
    }
  }

  // --- МЕБЕЛЬ ---------------------------------------------
  void _drawFurniture(Canvas canvas) {
    // Сортируем по «глубине» — (x + y) descending = дальние рисуем первыми
    final sorted = List<PlacedFurniture>.from(room.furniture)
      ..sort((a, b) => (a.gridX + a.gridY).compareTo(b.gridX + b.gridY));

    for (final item in sorted) {
      final isSelected = item.instanceId == selectedFurniture?.instanceId;
      _drawFurnitureItem(canvas, item, isSelected);
    }
  }

  void _drawFurnitureItem(Canvas canvas, PlacedFurniture item, bool selected) {
    final t = item.template;
    // Учитываем поворот: при 90/270° меняем w и h
    final (w, h) = _rotatedSize(t.tileWidth, t.tileHeight, item.rotation);

    // Собираем полигон всей площади мебели
    final tl = proj.toScreen(item.gridX.toDouble(), item.gridY.toDouble());
    final tr = proj.toScreen((item.gridX + w).toDouble(), item.gridY.toDouble());
    final br = proj.toScreen((item.gridX + w).toDouble(), (item.gridY + h).toDouble());
    final bl = proj.toScreen(item.gridX.toDouble(), (item.gridY + h).toDouble());

    const extraH = 28.0;

    // Верхняя грань
    final topPaint = Paint()..color = item.color;
    _fillPolygon(canvas, [tl, tr, br, bl], topPaint);

    // Передняя нижняя грань
    final frontPaint = Paint()..color = item.color.withOpacity(0.72);
    _fillPolygon(canvas, [
      bl,
      br,
      Offset(br.dx, br.dy - extraH),
      Offset(bl.dx, bl.dy - extraH),
    ], frontPaint);

    // Боковая правая грань
    final sidePaint = Paint()..color = item.color.withOpacity(0.55);
    _fillPolygon(canvas, [
      tr,
      br,
      Offset(br.dx, br.dy - extraH),
      Offset(tr.dx, tr.dy - extraH),
    ], sidePaint);

    // Обводка
    final strokePaint = Paint()
      ..color = selected
          ? AppTheme.accentColor
          : Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.5 : 1.0;
    _strokePolygon(canvas, [tl, tr, br, bl], strokePaint);

    // Эмодзи в центре
    final center = Offset(
      (tl.dx + br.dx) / 2,
      (tl.dy + br.dy) / 2 - extraH * 0.5,
    );
    _drawEmoji(canvas, t.emoji, center, fontSize: 18 + (w + h).toDouble());
  }

  // --- HOVER / DROP PREVIEW --------------------------------
  void _drawHoverHighlight(Canvas canvas) {
    if (hoverX == null || hoverY == null) return;
    final w = dragW ?? 1;
    final h = dragH ?? 1;

    final tl = proj.toScreen(hoverX!.toDouble(), hoverY!.toDouble());
    final tr = proj.toScreen((hoverX! + w).toDouble(), hoverY!.toDouble());
    final br = proj.toScreen((hoverX! + w).toDouble(), (hoverY! + h).toDouble());
    final bl = proj.toScreen(hoverX!.toDouble(), (hoverY! + h).toDouble());

    final fill = Paint()..color = AppTheme.primaryColor.withOpacity(0.22);
    _fillPolygon(canvas, [tl, tr, br, bl], fill);

    final stroke = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    _strokePolygon(canvas, [tl, tr, br, bl], stroke);
  }

  // --- СЕТКА (тонкий контур всех клеток) -----------------
  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int y = 0; y < room.gridHeight; y++) {
      for (int x = 0; x < room.gridWidth; x++) {
        _strokePolygon(canvas, proj.tileVertices(x.toDouble(), y.toDouble()), paint);
      }
    }
  }

  // --- УТИЛИТЫ --------------------------------------------
  void _fillPolygon(Canvas canvas, List<Offset> verts, Paint paint) {
    final path = Path()..moveTo(verts.first.dx, verts.first.dy);
    for (final v in verts.skip(1)) {
      path.lineTo(v.dx, v.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _strokePolygon(Canvas canvas, List<Offset> verts, Paint paint, {double? strokeWidth}) {
    final p = strokeWidth != null
        ? (Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth)
        : paint;
    _fillPolygon(canvas, verts, p);
  }

  void _drawEmoji(Canvas canvas, String emoji, Offset center,
      {required double fontSize}) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize.clamp(16, 32))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  (int, int) _rotatedSize(int w, int h, int rotation) {
    if (rotation == 90 || rotation == 270) return (h, w);
    return (w, h);
  }

  @override
  bool shouldRepaint(IsometricRoomPainter oldDelegate) =>
      oldDelegate.room != room ||
      oldDelegate.selectedFurniture?.instanceId != selectedFurniture?.instanceId ||
      oldDelegate.hoverX != hoverX ||
      oldDelegate.hoverY != hoverY;
}

// ─────────────────────────────────────────────────────────────
//  Виджет-обёртка с GestureDetector
// ─────────────────────────────────────────────────────────────

class IsometricRoomView extends StatefulWidget {
  final RoomLayout room;
  final PlacedFurniture? selectedFurniture;
  final FurnitureTemplate? pendingPlacement;
  final ValueChanged<PlacedFurniture>? onFurnitureSelected;
  final ValueChanged<(int, int)>? onTileTap;   // нажатие на пустую клетку
  final ValueChanged<(int, int)>? onFurnitureMoved;

  const IsometricRoomView({
    super.key,
    required this.room,
    this.selectedFurniture,
    this.pendingPlacement,
    this.onFurnitureSelected,
    this.onTileTap,
    this.onFurnitureMoved,
  });

  @override
  State<IsometricRoomView> createState() => _IsometricRoomViewState();
}

class _IsometricRoomViewState extends State<IsometricRoomView> {
  int? _hoverX, _hoverY;
  late IsoProjection _proj;

  IsoProjection _makeProjection(Size size) {
    final room = widget.room;
    // Центрируем комнату

    final totalH = (room.gridWidth + room.gridHeight) * 18.0;
    return IsoProjection(
      tileW: 72,
      tileH: 36,
      offsetX: size.width / 2,
      offsetY: (size.height - totalH) / 2 + 40,
    );
  }

  (int, int)? _screenToGrid(Offset pos, Size size) {
    final proj = _makeProjection(size);
    final g = proj.toGrid(pos);
    final gx = g.dx.floor();
    final gy = g.dy.floor();
    if (gx < 0 || gy < 0 || gx >= widget.room.gridWidth || gy >= widget.room.gridHeight) {
      return null;
    }
    return (gx, gy);
  }

  PlacedFurniture? _furnitureAt(int gx, int gy) {
    for (final f in widget.room.furniture) {
      final (w, h) = f.rotation == 90 || f.rotation == 270
          ? (f.template.tileHeight, f.template.tileWidth)
          : (f.template.tileWidth, f.template.tileHeight);
      if (gx >= f.gridX && gx < f.gridX + w &&
          gy >= f.gridY && gy < f.gridY + h) {
        return f;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = constraints.biggest;
      _proj = _makeProjection(size);

      return MouseRegion(
        onHover: (e) {
          final cell = _screenToGrid(e.localPosition, size);
          setState(() {
            _hoverX = cell?.$1;
            _hoverY = cell?.$2;
          });
        },
        onExit: (_) => setState(() {
          _hoverX = null;
          _hoverY = null;
        }),
        child: GestureDetector(
          onTapUp: (details) {
            final cell = _screenToGrid(details.localPosition, size);
            if (cell == null) return;
            final hit = _furnitureAt(cell.$1, cell.$2);
            if (hit != null) {
              widget.onFurnitureSelected?.call(hit);
            } else {
              widget.onTileTap?.call(cell);
            }
          },
          child: CustomPaint(
            size: size,
            painter: IsometricRoomPainter(
              room: widget.room,
              proj: _proj,
              selectedFurniture: widget.selectedFurniture,
              hoverX: _hoverX,
              hoverY: _hoverY,
              dragW: widget.pendingPlacement?.tileWidth,
              dragH: widget.pendingPlacement?.tileHeight,
            ),
          ),
        ),
      );
    });
  }
}
