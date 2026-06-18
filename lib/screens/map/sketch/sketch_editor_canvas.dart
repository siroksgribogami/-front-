import 'package:flutter/material.dart';

import '../../../config/brand_colors.dart';
import '../../../core/theme/brand_runtime.dart';
import '../../../core/theme/brand_ui.dart';
import 'sketch_geometry.dart';
import 'sketch_models.dart';
import 'sketch_recognizer.dart';

enum SketchTool { draw, select }

/// Полноценный полигональный редактор плана:
///  • рисуешь обводку пальцем → авто-выпрямление в комнату (как на планшете);
///  • выбираешь/двигаешь комнаты и тянешь углы;
///  • комнаты привязываются к сетке и соседним стенам, не перекрываются.
class SketchEditorCanvas extends StatefulWidget {
  const SketchEditorCanvas({
    super.key,
    required this.rooms,
    required this.onChanged,
    this.cell = 22,
  });

  final List<SketchRoom> rooms;
  final ValueChanged<List<SketchRoom>> onChanged;
  final double cell;

  @override
  State<SketchEditorCanvas> createState() => _SketchEditorCanvasState();
}

class _SketchEditorCanvasState extends State<SketchEditorCanvas> {
  SketchTool _tool = SketchTool.draw;
  String? _selectedId;

  // Рисование.
  SketchStroke? _stroke;

  // Перетаскивание.
  int _dragVertex = -1; // индекс вершины выбранной комнаты, иначе -1
  bool _movingRoom = false;
  Offset _lastPos = Offset.zero;
  List<Offset>? _dragBackup; // последнее валидное состояние полигона

  double get _cell => widget.cell;
  Size _size = Size.zero;
  int get _gridW => ((_size.width / _cell).ceil()) + 4;

  List<SketchRoom> get _rooms => widget.rooms;

  SketchRoom? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    for (final r in _rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  void _emit() => widget.onChanged(List.of(_rooms));

  // ── проверка перекрытия через занятые клетки ──────────────────────
  Set<int> _occupiedExcept(String? id) {
    final cells = <int>{};
    for (final r in _rooms) {
      if (r.id == id) continue;
      cells.addAll(SketchGeometry.occupiedCells(r.polygon, _cell, _gridW));
    }
    return cells;
  }

  bool _overlaps(List<Offset> poly, String? selfId) {
    final mine = SketchGeometry.occupiedCells(poly, _cell, _gridW);
    if (mine.isEmpty) return false;
    final others = _occupiedExcept(selfId);
    for (final c in mine) {
      if (others.contains(c)) return true;
    }
    return false;
  }

  // ── рисование ─────────────────────────────────────────────────────
  void _drawStart(Offset p) => setState(() => _stroke = SketchStroke(points: [p]));

  void _drawMove(Offset p) {
    final s = _stroke;
    if (s == null) return;
    if (s.points.isNotEmpty && (s.points.last - p).distanceSquared < 4) return;
    setState(() => s.points.add(p));
  }

  void _drawEnd() {
    final s = _stroke;
    setState(() => _stroke = null);
    if (s == null) return;
    final room = SketchRecognizer.recognize(
      s,
      cell: _cell,
      name: SketchPlan.autoName(_rooms.length),
    );
    if (room == null) return;

    final placed = _nudgeFree(room);
    _rooms.add(placed);
    _selectedId = placed.id;
    _tool = SketchTool.select;
    _emit();
  }

  /// Сдвигаем новую комнату к ближайшему свободному месту по сетке.
  SketchRoom _nudgeFree(SketchRoom room) {
    if (!_overlaps(room.polygon, room.id)) return room;
    for (var step = 1; step <= 60; step++) {
      for (final dir in const [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
      ]) {
        final cand = room.translated(dir * (step * _cell));
        if (!_overlaps(cand.polygon, room.id)) return cand;
      }
    }
    return room;
  }

  // ── выбор / перетаскивание ────────────────────────────────────────
  int _hitVertex(SketchRoom room, Offset p) {
    for (var i = 0; i < room.polygon.length; i++) {
      if ((room.polygon[i] - p).distance <= 18) return i;
    }
    return -1;
  }

  SketchRoom? _hitRoom(Offset p) {
    for (var i = _rooms.length - 1; i >= 0; i--) {
      if (SketchGeometry.contains(_rooms[i].polygon, p)) return _rooms[i];
    }
    return null;
  }

  void _selectStart(Offset p) {
    final sel = _selected;
    if (sel != null) {
      final v = _hitVertex(sel, p);
      if (v >= 0) {
        _dragVertex = v;
        _movingRoom = false;
        _lastPos = p;
        _dragBackup = List.of(sel.polygon);
        return;
      }
    }
    final hit = _hitRoom(p);
    if (hit != null) {
      _selectedId = hit.id;
      _dragVertex = -1;
      _movingRoom = true;
      _lastPos = p;
      _dragBackup = List.of(hit.polygon);
      setState(() {});
    } else {
      _dragVertex = -1;
      _movingRoom = false;
      setState(() => _selectedId = null);
    }
  }

  void _selectMove(Offset p) {
    final sel = _selected;
    if (sel == null) return;

    if (_dragVertex >= 0) {
      final snapped = SketchGeometry.snapToGrid(p, _cell);
      final poly = List.of(sel.polygon);
      poly[_dragVertex] = snapped;
      if (SketchGeometry.area(poly) > _cell * _cell &&
          !_overlaps(poly, sel.id)) {
        sel.polygon = poly;
        _dragBackup = List.of(poly);
        setState(() {});
      }
      return;
    }

    if (_movingRoom) {
      final rawDelta = p - _lastPos;
      // Двигаем от исходного бэкапа, чтобы привязка к сетке не «дёргалась».
      final base = _dragBackup ?? sel.polygon;
      final baseBounds = SketchGeometry.bounds(base);
      final targetTL = SketchGeometry.snapToGrid(
        baseBounds.topLeft + rawDelta,
        _cell,
      );
      final delta = targetTL - baseBounds.topLeft;
      var poly = base.map((v) => v + delta).toList();
      poly = _edgeSnap(poly, sel.id);
      if (!_overlaps(poly, sel.id)) {
        sel.polygon = poly;
        setState(() {});
      }
      // при перекрытии остаёмся на последней валидной позиции → «прилипание»
    }
  }

  void _selectEnd() {
    if (_dragVertex >= 0 || _movingRoom) _emit();
    _dragVertex = -1;
    _movingRoom = false;
    _dragBackup = null;
  }

  /// Притягиваем края перемещаемой комнаты к стенам соседей (стык-в-стык).
  List<Offset> _edgeSnap(List<Offset> poly, String selfId) {
    const snap = 14.0;
    final b = SketchGeometry.bounds(poly);
    double bestDx = 0, bestDy = 0;
    var foundX = false, foundY = false;
    for (final r in _rooms) {
      if (r.id == selfId) continue;
      final ob = r.bounds;
      for (final mine in [b.left, b.right]) {
        for (final other in [ob.left, ob.right]) {
          final d = other - mine;
          if (d.abs() < snap && (!foundX || d.abs() < bestDx.abs())) {
            bestDx = d;
            foundX = true;
          }
        }
      }
      for (final mine in [b.top, b.bottom]) {
        for (final other in [ob.top, ob.bottom]) {
          final d = other - mine;
          if (d.abs() < snap && (!foundY || d.abs() < bestDy.abs())) {
            bestDy = d;
            foundY = true;
          }
        }
      }
    }
    final shift = Offset(foundX ? bestDx : 0, foundY ? bestDy : 0);
    if (shift == Offset.zero) return poly;
    final shifted = poly.map((v) => v + shift).toList();
    return _overlaps(shifted, selfId) ? poly : shifted;
  }

  // ── действия ──────────────────────────────────────────────────────
  void _deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    _rooms.removeWhere((r) => r.id == id);
    _selectedId = null;
    _emit();
    setState(() {});
  }

  Future<void> _renameSelected() async {
    final sel = _selected;
    if (sel == null) return;
    final ctrl = TextEditingController(text: sel.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Название комнаты'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Например, Кухня'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      sel.name = result;
      _emit();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111316) : const Color(0xFFF5F1E8);
    final grid =
        isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final pen = isDark ? Colors.white.withOpacity(0.92) : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: bg,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _tool == SketchTool.select
                        ? (d) {
                            final hit = _hitRoom(d.localPosition);
                            setState(() => _selectedId = hit?.id);
                          }
                        : null,
                    onDoubleTapDown: _tool == SketchTool.select
                        ? (d) {
                            final hit = _hitRoom(d.localPosition);
                            if (hit != null) {
                              _selectedId = hit.id;
                              _renameSelected();
                            }
                          }
                        : null,
                    onDoubleTap: _tool == SketchTool.select ? () {} : null,
                    onPanStart: (d) => _tool == SketchTool.draw
                        ? _drawStart(d.localPosition)
                        : _selectStart(d.localPosition),
                    onPanUpdate: (d) => _tool == SketchTool.draw
                        ? _drawMove(d.localPosition)
                        : _selectMove(d.localPosition),
                    onPanEnd: (_) =>
                        _tool == SketchTool.draw ? _drawEnd() : _selectEnd(),
                    onPanCancel: () =>
                        _tool == SketchTool.draw ? _drawEnd() : _selectEnd(),
                    child: CustomPaint(
                      painter: _EditorPainter(
                        rooms: _rooms,
                        selectedId: _selectedId,
                        stroke: _stroke,
                        cell: _cell,
                        gridColor: grid,
                        penColor: pen,
                        showHandles: _tool == SketchTool.select,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                Positioned(left: 12, top: 12, child: _toolbar()),
                if (_tool == SketchTool.select && _selected != null)
                  Positioned(right: 12, top: 12, child: _selectionActions()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolbar() {
    Widget btn(SketchTool tool, IconData icon, String tip) {
      final on = _tool == tool;
      return Tooltip(
        message: tip,
        child: InkWell(
          onTap: () => setState(() {
            _tool = tool;
            _stroke = null;
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: on ? BrandColors.clay : BrandRuntime.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: on ? BrandColors.clay : BrandRuntime.border,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: on ? BrandColors.onClay : BrandRuntime.ink.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        btn(SketchTool.draw, Icons.gesture, 'Рисовать комнату'),
        const SizedBox(height: 8),
        btn(SketchTool.select, Icons.pan_tool_alt_outlined, 'Двигать / править'),
      ],
    );
  }

  Widget _selectionActions() {
    Widget chip(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BrandRuntime.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BrandRuntime.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: BrandRuntime.ink.withOpacity(0.75)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: BrandUi.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BrandRuntime.ink.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        chip(Icons.edit_outlined, 'Имя', _renameSelected),
        const SizedBox(height: 8),
        chip(Icons.delete_outline, 'Удалить', _deleteSelected),
      ],
    );
  }
}

class _EditorPainter extends CustomPainter {
  _EditorPainter({
    required this.rooms,
    required this.selectedId,
    required this.stroke,
    required this.cell,
    required this.gridColor,
    required this.penColor,
    required this.showHandles,
  });

  final List<SketchRoom> rooms;
  final String? selectedId;
  final SketchStroke? stroke;
  final double cell;
  final Color gridColor;
  final Color penColor;
  final bool showHandles;

  @override
  void paint(Canvas canvas, Size size) {
    // сетка
    final gp = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }

    for (final room in rooms) {
      final selected = room.id == selectedId;
      _paintRoom(canvas, room, selected);
    }

    // текущий штрих рисования
    final s = stroke;
    if (s != null && s.points.length > 1) {
      final pen = Paint()
        ..color = penColor
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, pen);
    }
  }

  void _paintRoom(Canvas canvas, SketchRoom room, bool selected) {
    if (room.polygon.length < 3) return;
    final accent = selected ? BrandColors.clay : BrandColors.needles;
    final fill = Paint()
      ..color = accent.withOpacity(selected ? 0.18 : 0.12)
      ..style = PaintingStyle.fill;
    final wall = Paint()
      ..color = accent
      ..strokeWidth = selected ? 3 : 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(room.polygon.first.dx, room.polygon.first.dy);
    for (final p in room.polygon.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, wall);

    // подпись
    final c = room.centroid;
    final tp = TextPainter(
      text: TextSpan(
        text: room.name,
        style: TextStyle(
          color: selected ? BrandColors.clay : BrandColors.needlesDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: room.bounds.width);
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));

    // ручки вершин у выбранной комнаты
    if (selected && showHandles) {
      final handleFill = Paint()..color = Colors.white;
      final handleStroke = Paint()
        ..color = BrandColors.clay
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      for (final v in room.polygon) {
        canvas.drawCircle(v, 6, handleFill);
        canvas.drawCircle(v, 6, handleStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EditorPainter old) =>
      old.rooms != rooms ||
      old.selectedId != selectedId ||
      old.stroke != stroke ||
      old.gridColor != gridColor ||
      old.penColor != penColor ||
      old.showHandles != showHandles;
}
