import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/brand_runtime.dart';

import '../../../config/brand_colors.dart';
import '../../../config/text_theme.dart';
import '../../../core/arthouse_scroll_behavior.dart';
import '../../../core/theme/brand_ui.dart';
import '../../../models/map_floor_plan.dart';
import 'sketch_editor_canvas.dart';
import 'sketch_geometry.dart';
import 'sketch_models.dart';

/// Результат мастера: один или несколько этажей.
class SketchPlanResult {
  SketchPlanResult({
    required this.floors,
    required this.totalAreaSqM,
  });

  final List<MapFloorData> floors;
  final int totalAreaSqM;

  List<Map<String, dynamic>> get rooms => MapFloorPlanHelper.flattenRooms(floors);
}

class _FloorSketch {
  _FloorSketch({required this.index, required this.label});

  int index;
  String label;
  final List<SketchRoom> rooms = [];
  int areaSqM = 40;
}

/// Мастер «Рисование плана» с поддержкой нескольких этажей.
class SketchPlanWizard extends StatefulWidget {
  const SketchPlanWizard({
    super.key,
    this.initialAreaSqM = 60,
    this.initialFloorCount = 1,
    this.maxFloors = 10,
    this.existingFloors,
  });

  final int initialAreaSqM;
  final int initialFloorCount;
  final int maxFloors;
  final List<MapFloorData>? existingFloors;

  @override
  State<SketchPlanWizard> createState() => _SketchPlanWizardState();
}

class _SketchPlanWizardState extends State<SketchPlanWizard> {
  int _step = 0;
  late final List<_FloorSketch> _floors;
  int _activeFloor = 0;

  _FloorSketch get _current => _floors[_activeFloor];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingFloors;
    if (existing != null && existing.isNotEmpty) {
      _floors = existing
          .map(
            (f) => _FloorSketch(index: f.index, label: f.label)
              ..areaSqM = f.areaSqm ??
                  (widget.initialAreaSqM ~/ existing.length).clamp(18, 250),
          )
          .toList();
    } else {
      final count = widget.initialFloorCount.clamp(1, widget.maxFloors);
      final perFloor = (widget.initialAreaSqM / count).round().clamp(18, 250);
      _floors = List.generate(
        count,
        (i) => _FloorSketch(
          index: i,
          label: MapFloorPlanHelper.labelForIndex(i),
        )..areaSqM = perFloor,
      );
    }
  }

  void _onRoomsChanged(List<SketchRoom> next) {
    setState(() {
      _current.rooms
        ..clear()
        ..addAll(next);
    });
  }

  void _undo() {
    if (_current.rooms.isEmpty) return;
    setState(() => _current.rooms.removeLast());
  }

  void _clear() {
    if (_current.rooms.isEmpty) return;
    setState(() => _current.rooms.clear());
  }

  void _addFloor() {
    if (_floors.length >= widget.maxFloors) return;
    setState(() {
      final idx = _floors.length;
      _floors.add(
        _FloorSketch(index: idx, label: MapFloorPlanHelper.labelForIndex(idx))
          ..areaSqM = 40,
      );
      _activeFloor = idx;
    });
  }

  void _removeActiveFloor() {
    if (_floors.length <= 1) return;
    setState(() {
      _floors.removeAt(_activeFloor);
      for (var i = 0; i < _floors.length; i++) {
        _floors[i].index = i;
        _floors[i].label = MapFloorPlanHelper.labelForIndex(i);
      }
      _activeFloor = _activeFloor.clamp(0, _floors.length - 1);
    });
  }

  bool get _hasAnyRooms => _floors.any((f) => f.rooms.isNotEmpty);

  void _next() {
    if (_step == 0) {
      if (!_hasAnyRooms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нарисуйте хотя бы одну комнату на любом этаже'),
          ),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  List<Map<String, dynamic>> _roomsFromFloor(
    List<SketchRoom> rooms,
    int areaSqM,
    int floorIndex,
  ) {
    if (rooms.isEmpty) return [];

    var bbox = rooms.first.bounds;
    for (final r in rooms.skip(1)) {
      bbox = bbox.expandToInclude(r.bounds);
    }
    if (bbox.width <= 0 || bbox.height <= 0) return [];

    final totalPolyArea =
        rooms.fold<double>(0, (s, r) => s + r.areaPx).clamp(1, double.infinity);
    final scalePxToM = math.sqrt(areaSqM / totalPolyArea);

    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      final rb = room.bounds;
      final widthM = rb.width * scalePxToM;
      final heightM = rb.height * scalePxToM;
      final areaM = (room.areaPx * scalePxToM * scalePxToM).round();
      final polygonM = room.polygon
          .map((p) => {
                'x': double.parse(
                    ((p.dx - bbox.left) * scalePxToM).toStringAsFixed(2)),
                'y': double.parse(
                    ((p.dy - bbox.top) * scalePxToM).toStringAsFixed(2)),
              })
          .toList();

      out.add({
        'displayName': room.name,
        'name': room.name,
        'area_sqm': areaM,
        'width_m': double.parse(widthM.toStringAsFixed(2)),
        'height_m': double.parse(heightM.toStringAsFixed(2)),
        'origin_x_m': double.parse(
            ((rb.left - bbox.left) * scalePxToM).toStringAsFixed(2)),
        'origin_y_m': double.parse(
            ((rb.top - bbox.top) * scalePxToM).toStringAsFixed(2)),
        'polygon_m': polygonM,
        'shape': room.isRect ? 'rect' : 'polygon',
        'room_id': 'sketch_f${floorIndex}_$i',
        'floor_index': floorIndex,
      });
    }
    return out;
  }

  void _finish() {
    final resultFloors = <MapFloorData>[];
    for (final f in _floors) {
      if (f.rooms.isEmpty) continue;
      final rooms = _roomsFromFloor(f.rooms, f.areaSqM, f.index);
      if (rooms.isEmpty) continue;
      resultFloors.add(
        MapFloorData(
          index: f.index,
          label: f.label,
          rooms: rooms,
          areaSqm: f.areaSqM,
        ),
      );
    }

    if (resultFloors.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final total = MapFloorPlanHelper.totalAreaSqm(resultFloors);
    Navigator.of(context).pop<SketchPlanResult>(
      SketchPlanResult(floors: resultFloors, totalAreaSqM: total),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandAppBar(
              title: 'План этажа',
              subtitle: _step == 0
                  ? 'Рисуйте комнаты, затем двигайте и правьте'
                  : 'Укажите площадь по этажам',
              onBack: _back,
              actions: TextButton(
                onPressed: _step == 0 ? _next : _finish,
                child: Text(
                  _step == 0 ? 'Готово' : 'Сохранить',
                  style: BrandUi.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.clay,
                  ),
                ),
              ),
            ),
            if (_step == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildFloorTabs(),
              ),
            Expanded(
              child: _step == 0 ? _buildDrawStep() : _buildSizeStep(),
            ),
            if (_step == 0) _buildDrawControls() else _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _floors.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeFloor = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeFloor == i
                        ? BrandRuntime.needlesFill
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _activeFloor == i
                          ? BrandRuntime.needlesFill
                          : BrandRuntime.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _floors[i].label,
                    style: BrandUi.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _activeFloor == i
                          ? BrandColors.onNeedles
                          : BrandRuntime.ink.withOpacity(0.55),
                    ),
                  ),
                ),
              ),
            ),
          if (_floors.length < widget.maxFloors)
            GestureDetector(
              onTap: _addFloor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BrandRuntime.border, width: 1.5),
                ),
                child: Text(
                  '+ Этаж',
                  style: BrandUi.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrandRuntime.ink.withOpacity(0.55),
                  ),
                ),
              ),
            ),
          if (_floors.length > 1)
            IconButton(
              tooltip: 'Удалить этаж',
              onPressed: _removeActiveFloor,
              icon: Icon(
                Icons.delete_outline,
                color: BrandRuntime.ink.withOpacity(0.45),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawStep() {
    final cur = _current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Stack(
        children: [
          Positioned.fill(
            child: SketchEditorCanvas(
              key: ValueKey('floor_${cur.index}'),
              rooms: cur.rooms,
              onChanged: _onRoomsChanged,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BrandRuntime.card.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: BrandRuntime.border),
                ),
                child: Text(
                  cur.rooms.isEmpty
                      ? 'РЕЖИМ КИСТИ · ОБВЕДИТЕ КОМНАТУ'
                      : '${cur.rooms.length} КОМН. · ✎ двигайте и тяните углы',
                  style: BrandUi.monoLabel(
                    fontSize: 10,
                    color: BrandRuntime.ink.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawControls() {
    final cur = _current;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            BrandGhostButton(
              label: 'Отменить',
              onPressed: cur.rooms.isEmpty ? null : _undo,
            ),
            const SizedBox(width: 10),
            BrandGhostButton(
              label: 'Очистить',
              onPressed: cur.rooms.isEmpty ? null : _clear,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BrandAccentButton(
                label: 'Далее',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeStep() {
    final withRooms = _floors.where((f) => f.rooms.isNotEmpty).toList();
    if (withRooms.isEmpty) {
      return Center(
        child: Text(
          'Сначала нарисуйте план этажа',
          style: BrandUi.inter(color: BrandRuntime.ink.withOpacity(0.55)),
        ),
      );
    }

    final totalArea = withRooms.fold<int>(0, (s, f) => s + f.areaSqM);

    return ScrollConfiguration(
      behavior: const ArthouseScrollBehavior(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          Text(
            'Всего: $totalArea м² · этажей: ${withRooms.length}',
            style: BrandUi.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final f in withRooms) ...[
            BrandCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(f.label,
                      style: BrandUi.inter(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _PlanPreview(rooms: f.rooms),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${f.areaSqM}',
                        style: pochaevsk(
                          fontSize: 26,
                          color: BrandRuntime.needles,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('м²',
                            style: BrandUi.inter(
                                color: BrandRuntime.ink.withOpacity(0.55))),
                      ),
                      const Spacer(),
                      Text(
                        '${f.rooms.length} комн.',
                        style: BrandUi.inter(
                          fontSize: 12,
                          color: BrandRuntime.ink.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: f.areaSqM.toDouble(),
                    min: 12,
                    max: 400,
                    divisions: 388,
                    activeColor: BrandColors.clay,
                    onChanged: (v) => setState(() => f.areaSqM = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: BrandAccentButton(label: 'Готово', onPressed: _finish),
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.rooms});
  final List<SketchRoom> rooms;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _PreviewPainter(rooms: rooms, accent: BrandColors.clay),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.rooms, required this.accent});
  final List<SketchRoom> rooms;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (rooms.isEmpty) return;
    var bbox = rooms.first.bounds;
    for (final r in rooms.skip(1)) {
      bbox = bbox.expandToInclude(r.bounds);
    }
    if (bbox.width <= 0 || bbox.height <= 0) return;

    final scale = math.min(
      (size.width - 32) / bbox.width,
      (size.height - 32) / bbox.height,
    );
    final dx = (size.width - bbox.width * scale) / 2 - bbox.left * scale;
    final dy = (size.height - bbox.height * scale) / 2 - bbox.top * scale;

    final fill = Paint()
      ..color = accent.withOpacity(0.16)
      ..style = PaintingStyle.fill;
    final wall = Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    for (final room in rooms) {
      if (room.polygon.length < 3) continue;
      final path = Path();
      for (var i = 0; i < room.polygon.length; i++) {
        final p = room.polygon[i];
        final sp = Offset(p.dx * scale + dx, p.dy * scale + dy);
        if (i == 0) {
          path.moveTo(sp.dx, sp.dy);
        } else {
          path.lineTo(sp.dx, sp.dy);
        }
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, wall);

      final c = SketchGeometry.centroid(room.polygon);
      final tp = TextPainter(
        text: TextSpan(
          text: room.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(c.dx * scale + dx - tp.width / 2,
            c.dy * scale + dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.rooms != rooms || old.accent != accent;
}
