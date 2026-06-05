import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../config/brand_colors.dart';
import '../../../config/text_theme.dart';
import '../../../core/arthouse_scroll_behavior.dart';
import '../../../core/theme/brand_ui.dart';
import '../../../models/map_floor_plan.dart';
import 'sketch_canvas.dart';
import 'sketch_models.dart';
import 'sketch_rectifier.dart';

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
  _FloorSketch({
    required this.index,
    required this.label,
  });

  int index;
  String label;
  final List<SketchStroke> strokes = [];
  SketchPlan? plan;
  int areaSqM = 40;
}

/// Мастер «Свободное рисование» с поддержкой нескольких этажей.
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
              ..areaSqM = f.areaSqm ?? (widget.initialAreaSqM ~/ existing.length).clamp(18, 250),
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

  void _onStrokesChanged(List<SketchStroke> next) {
    setState(() {
      _current.strokes
        ..clear()
        ..addAll(next);
      _current.plan = null;
    });
  }

  void _undo() {
    if (_current.strokes.isEmpty) return;
    setState(() {
      _current.strokes.removeLast();
      _current.plan = null;
    });
  }

  void _clear() {
    setState(() {
      _current.strokes.clear();
      _current.plan = null;
    });
  }

  void _rectifyIfNeeded(Size canvasSize) {
    if (_current.strokes.isEmpty) {
      _current.plan = null;
      return;
    }
    final plan = SketchRectifier.rectify(_current.strokes, canvasSize);
    _current.plan = plan.rooms.isEmpty ? null : plan;
  }

  void _addFloor() {
    if (_floors.length >= widget.maxFloors) return;
    setState(() {
      final idx = _floors.length;
      _floors.add(
        _FloorSketch(
          index: idx,
          label: MapFloorPlanHelper.labelForIndex(idx),
        )..areaSqM = 40,
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

  bool get _hasAnyRooms =>
      _floors.any((f) => f.plan != null && f.plan!.rooms.isNotEmpty);

  void _next(Size canvasSize) {
    if (_step == 0) {
      _rectifyIfNeeded(canvasSize);
      for (final f in _floors) {
        if (f.strokes.isNotEmpty && (f.plan == null || f.plan!.rooms.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'На «${f.label}» нажмите «Выпрямить» или очистите этаж',
              ),
            ),
          );
          setState(() => _activeFloor = _floors.indexOf(f));
          return;
        }
      }
      if (!_hasAnyRooms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Нарисуйте хотя бы одну комнату на любом этаже',
            ),
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

  List<Map<String, dynamic>> _roomsFromPlan(SketchPlan plan, int areaSqM, int floorIndex) {
    final bbox = plan.bounds;
    if (bbox.width <= 0 || bbox.height <= 0) return [];

    final pxArea = bbox.width * bbox.height;
    final scalePxToM = math.sqrt(areaSqM / pxArea);

    final rooms = <Map<String, dynamic>>[];
    for (var i = 0; i < plan.rooms.length; i++) {
      final room = plan.rooms[i];
      final widthM = room.rect.width * scalePxToM;
      final heightM = room.rect.height * scalePxToM;
      final area = (widthM * heightM).round();
      rooms.add({
        'displayName': room.name,
        'name': room.name,
        'area_sqm': area,
        'width_m': double.parse(widthM.toStringAsFixed(2)),
        'height_m': double.parse(heightM.toStringAsFixed(2)),
        'origin_x_m': double.parse(
          ((room.rect.left - bbox.left) * scalePxToM).toStringAsFixed(2),
        ),
        'origin_y_m': double.parse(
          ((room.rect.top - bbox.top) * scalePxToM).toStringAsFixed(2),
        ),
        'room_id': 'sketch_f${floorIndex}_$i',
        'floor_index': floorIndex,
      });
    }
    return rooms;
  }

  void _finish() {
    final resultFloors = <MapFloorData>[];
    for (final f in _floors) {
      final plan = f.plan;
      if (plan == null || plan.rooms.isEmpty) continue;
      final rooms = _roomsFromPlan(plan, f.areaSqM, f.index);
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
      backgroundColor: BrandColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandAppBar(
              title: 'Эскиз плана',
              subtitle: _step == 0
                  ? 'Обведите контур комнаты пальцем'
                  : 'Укажите площадь по этажам',
              onBack: _back,
              actions: TextButton(
                onPressed: _step == 0
                    ? () => _next(Size(
                          MediaQuery.sizeOf(context).width - 32,
                          MediaQuery.sizeOf(context).height * 0.55,
                        ))
                    : _finish,
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
            if (_step == 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildFloorTabs(),
              ),
            ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeFloor == i
                        ? BrandColors.needles
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _activeFloor == i
                          ? BrandColors.needles
                          : BrandColors.borderSubtle,
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
                          : BrandColors.tar.withOpacity(0.55),
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
                  border: Border.all(color: BrandColors.borderSubtle, width: 1.5),
                ),
                child: Text(
                  '+ Этаж',
                  style: BrandUi.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.tar.withOpacity(0.55),
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
                color: BrandColors.tar.withOpacity(0.45),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Площадь, м²',
                        style: BrandUi.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.tar.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: '${cur.areaSqM}.0',
                        keyboardType: TextInputType.number,
                        decoration: BrandUi.inputDecoration(),
                        onChanged: (v) {
                          final n = int.tryParse(v.split('.').first);
                          if (n != null) cur.areaSqM = n.clamp(12, 400);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                BrandGhostButton(
                  label: 'Выпрямить',
                  onPressed: cur.strokes.isEmpty
                      ? null
                      : () {
                          final size = MediaQuery.sizeOf(context);
                          setState(
                            () => _rectifyIfNeeded(
                              Size(size.width - 32, size.height * 0.45),
                            ),
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                BrandGhostButton(
                  label: 'Отменить',
                  onPressed: cur.strokes.isEmpty ? null : _undo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BrandAccentButton(
                    label: 'Сохранить план',
                    onPressed: () => _next(
                      Size(
                        MediaQuery.sizeOf(context).width - 32,
                        MediaQuery.sizeOf(context).height * 0.55,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawStep() {
    final cur = _current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return BrandGridCanvas(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SketchCanvas(
                  strokes: cur.strokes,
                  preview: cur.plan,
                  onStrokesChanged: _onStrokesChanged,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BrandColors.milk,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: BrandColors.borderSubtle),
                    ),
                    child: Text(
                      cur.plan != null
                          ? '${cur.plan!.rooms.length} КОМН. · ВЫПРЯМЛЕНО'
                          : '${cur.strokes.length} МАЗКОВ · РИСУЙТЕ',
                      style: BrandUi.monoLabel(
                        fontSize: 10,
                        color: BrandColors.tar.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _ActionDock(
                    onUndo: cur.strokes.isEmpty ? null : _undo,
                    onClear: cur.strokes.isEmpty ? null : _clear,
                    onRectify: cur.strokes.isEmpty
                        ? null
                        : () {
                            setState(() => _rectifyIfNeeded(size));
                            if (cur.plan == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Не получилось распознать комнаты — обведите крупнее и замкните линию',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSizeStep() {
    final withPlan = _floors.where((f) => f.plan != null && f.plan!.rooms.isNotEmpty).toList();
    if (withPlan.isEmpty) {
      return Center(
        child: Text(
          'Сначала нарисуйте план этажа',
          style: BrandUi.inter(color: BrandColors.tar.withOpacity(0.55)),
        ),
      );
    }

    final totalArea = withPlan.fold<int>(0, (s, f) => s + f.areaSqM);

    return ScrollConfiguration(
      behavior: const ArthouseScrollBehavior(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          Text(
            'Всего: $totalArea м² · этажей: ${withPlan.length}',
            style: BrandUi.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final f in withPlan) ...[
            BrandCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    f.label,
                    style: BrandUi.inter(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _PlanPreview(plan: f.plan!),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${f.areaSqM}',
                        style: pochaevsk(
                          fontSize: 26,
                          color: BrandColors.needles,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'м²',
                          style: BrandUi.inter(
                            color: BrandColors.tar.withOpacity(0.55),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${f.plan!.rooms.length} комн.',
                        style: BrandUi.inter(
                          fontSize: 12,
                          color: BrandColors.tar.withOpacity(0.55),
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
        child: BrandAccentButton(
          label: 'Готово',
          onPressed: _finish,
        ),
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({this.onUndo, this.onClear, this.onRectify});

  final VoidCallback? onUndo;
  final VoidCallback? onClear;
  final VoidCallback? onRectify;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.milk.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: BrandColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: BrandColors.tar.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DockButton(icon: Icons.undo, label: 'Отменить', onTap: onUndo),
          _DockButton(icon: Icons.delete_outline, label: 'Очистить', onTap: onClear),
          _DockButton(
            icon: Icons.auto_fix_high,
            label: 'Выпрямить',
            highlighted: true,
            onTap: onRectify,
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = highlighted && enabled
        ? BrandColors.clay
        : BrandColors.tar.withOpacity(enabled ? 0.75 : 0.3);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 2),
            Text(label, style: BrandUi.inter(color: fg, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.plan});
  final SketchPlan plan;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _PreviewPainter(
          plan: plan,
          accent: BrandColors.clay,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.plan, required this.accent});
  final SketchPlan plan;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (plan.rooms.isEmpty) return;
    final bbox = plan.bounds;
    final scale = math.min(
      (size.width - 32) / bbox.width,
      (size.height - 32) / bbox.height,
    );
    final dx = (size.width - bbox.width * scale) / 2 - bbox.left * scale;
    final dy = (size.height - bbox.height * scale) / 2 - bbox.top * scale;

    final fill = Paint()
      ..color = accent.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final wall = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final label = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    for (final room in plan.rooms) {
      final r = Rect.fromLTRB(
        room.rect.left * scale + dx,
        room.rect.top * scale + dy,
        room.rect.right * scale + dx,
        room.rect.bottom * scale + dy,
      );
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, wall);

      final paragraph = (ui.ParagraphBuilder(label)
            ..pushStyle(ui.TextStyle(color: Colors.white))
            ..addText(room.name))
          .build()
        ..layout(ui.ParagraphConstraints(width: r.width));
      canvas.drawParagraph(
        paragraph,
        Offset(r.left, r.center.dy - paragraph.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.plan != plan || old.accent != accent;
}
