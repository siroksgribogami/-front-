import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../providers/map_editor_provider.dart';

const _terra = Color(0xFFD4956A);
const _dark = Color(0xFF2A3A2C);
const _canvasDark = Color(0xFF16120F);

class _RoomSlot {
  const _RoomSlot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.floorColor,
    required this.labelDx,
    required this.labelDy,
    required this.furniture,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Color floorColor;
  final double labelDx;
  final double labelDy;
  final List<Alignment> furniture;
}

class ApartmentOverview extends StatefulWidget {
  const ApartmentOverview({super.key, required this.onRoomTap});

  final void Function(int roomIndex) onRoomTap;

  @override
  State<ApartmentOverview> createState() => _ApartmentOverviewState();
}

class _ApartmentOverviewState extends State<ApartmentOverview> {
  static const _gridW = 18.0;
  static const _gridH = 11.0;
  static const _wallDepth = 16.0;

  static const _slots = <_RoomSlot>[
    _RoomSlot(
      left: 0,
      top: 0,
      width: 8,
      height: 6,
      floorColor: Color(0xFFECE5D8),
      labelDx: 0.16,
      labelDy: 0.22,
      furniture: [Alignment(-0.30, 0.12), Alignment(0.22, 0.30), Alignment(0.52, -0.18)],
    ),
    _RoomSlot(
      left: 0,
      top: 6,
      width: 6,
      height: 5,
      floorColor: Color(0xFFE4DCCF),
      labelDx: 0.20,
      labelDy: 0.15,
      furniture: [Alignment(-0.15, 0.10), Alignment(0.38, 0.34)],
    ),
    _RoomSlot(
      left: 8,
      top: 0,
      width: 6,
      height: 6,
      floorColor: Color(0xFFE9E0D2),
      labelDx: 0.26,
      labelDy: 0.26,
      furniture: [Alignment(-0.20, -0.18), Alignment(0.18, 0.18), Alignment(0.56, 0.40)],
    ),
    _RoomSlot(
      left: 14,
      top: 0,
      width: 4,
      height: 6,
      floorColor: Color(0xFFDCE4E1),
      labelDx: 0.18,
      labelDy: 0.20,
      furniture: [Alignment(-0.10, -0.15), Alignment(0.18, 0.24)],
    ),
    _RoomSlot(
      left: 6,
      top: 6,
      width: 5,
      height: 5,
      floorColor: Color(0xFFE2DACE),
      labelDx: 0.18,
      labelDy: 0.16,
      furniture: [Alignment(-0.15, 0.15), Alignment(0.40, 0.00)],
    ),
    _RoomSlot(
      left: 11,
      top: 6,
      width: 7,
      height: 5,
      floorColor: Color(0xFFE7E0D5),
      labelDx: 0.20,
      labelDy: 0.16,
      furniture: [Alignment(-0.28, 0.12), Alignment(0.14, 0.32), Alignment(0.44, -0.14)],
    ),
  ];

  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<MapEditorProvider>().rooms;
    final totalTasks = rooms.fold<int>(0, (sum, room) => sum + room.tasksCount);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E2D8),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
            child: Row(
              children: [
                Text(
                  'МОЙ ДОМ <3',
                  style: AppTextStyle.gropled(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8D4CC)),
                  ),
                  child: Text(
                    'Общий 3D-вид квартиры',
                    style: TextStyle(
                      fontFamily: AppTextStyle.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _dark.withOpacity(0.78),
                    ),
                  ),
                ),
                const Spacer(),
                if (totalTasks > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _terra,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _terra.withOpacity(0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '$totalTasks ${_taskWord(totalTasks)}',
                          style: const TextStyle(
                            fontFamily: AppTextStyle.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF211914), _canvasDark, Color(0xFF120E0C)],
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      const sceneAspect = 1.52;
                      double sceneW;
                      double sceneH;
                      if (box.maxWidth / box.maxHeight > sceneAspect) {
                        sceneH = box.maxHeight * 0.84;
                        sceneW = sceneH * sceneAspect;
                      } else {
                        sceneW = box.maxWidth * 0.84;
                        sceneH = sceneW / sceneAspect;
                      }

                      final left = (box.maxWidth - sceneW) / 2;
                      final top = (box.maxHeight - sceneH) / 2;
                      final planW = sceneW * 0.82;
                      final planH = sceneH * 0.66;
                      final planLeft = left + (sceneW - planW) / 2;
                      final planTop = top + sceneH * 0.18;

                      return Stack(
                        children: [
                          Positioned.fill(child: _buildBackgroundGlow()),
                          Positioned(
                            left: planLeft - 80,
                            top: planTop + planH * 0.58,
                            width: planW + 160,
                            height: planH * 0.70,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.45),
                                      blurRadius: 90,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: planLeft,
                            top: planTop,
                            width: planW,
                            height: planH + _wallDepth * 2,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0013)
                                ..rotateX(0.92)
                                ..rotateZ(-0.17),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.14),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (var i = 0; i < rooms.length && i < _slots.length; i++)
                                    Positioned(
                                      left: (_slots[i].left / _gridW) * planW,
                                      top: (_slots[i].top / _gridH) * planH,
                                      width: (_slots[i].width / _gridW) * planW,
                                      height: (_slots[i].height / _gridH) * planH,
                                      child: _RoomPrism(
                                        slot: _slots[i],
                                        depth: _wallDepth,
                                        hovered: _hoveredIndex == i,
                                        onEnter: () => setState(() => _hoveredIndex = i),
                                        onExit: () => setState(() => _hoveredIndex = null),
                                        onTap: () => widget.onRoomTap(i),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          for (var i = 0; i < rooms.length && i < _slots.length; i++)
                            _buildRoomChip(i, rooms[i], _slots[i], planLeft, planTop, planW, planH),
                          for (var i = 0; i < rooms.length && i < _slots.length; i++)
                            if (rooms[i].tasksCount > 0)
                              _buildTaskBadge(i, rooms[i], _slots[i], planLeft, planTop, planW, planH),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 12,
                            child: Center(
                              child: Text(
                                'Нажмите на комнату, чтобы открыть её редактор',
                                style: TextStyle(
                                  fontFamily: AppTextStyle.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Stack(
      children: [
        Positioned(
          left: -120,
          top: -40,
          width: 360,
          height: 360,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.08), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: 10,
          width: 260,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_terra.withOpacity(0.12), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomChip(
    int index,
    MapEditorRoom room,
    _RoomSlot slot,
    double planLeft,
    double planTop,
    double planW,
    double planH,
  ) {
    final chipLeft = planLeft + ((slot.left + slot.width * slot.labelDx) / _gridW) * planW;
    final chipTop = planTop + ((slot.top + slot.height * slot.labelDy) / _gridH) * planH;
    final active = _hoveredIndex == index;

    return Positioned(
      left: chipLeft,
      top: chipTop,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () => widget.onRoomTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? _terra.withOpacity(0.92) : const Color(0xAA5B4E45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? _terra : Colors.white.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(active ? 0.32 : 0.22),
                  blurRadius: active ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(room.icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  room.name,
                  style: const TextStyle(
                    fontFamily: AppTextStyle.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskBadge(
    int index,
    MapEditorRoom room,
    _RoomSlot slot,
    double planLeft,
    double planTop,
    double planW,
    double planH,
  ) {
    final badgeLeft = planLeft + ((slot.left + slot.width * 0.55) / _gridW) * planW;
    final badgeTop = planTop - 10 + ((slot.top + slot.height * 0.10) / _gridH) * planH;

    return Positioned(
      left: badgeLeft,
      top: badgeTop,
      child: GestureDetector(
        onTap: () => widget.onRoomTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8B8C1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8B8C1).withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${room.tasksCount}',
                style: const TextStyle(
                  fontFamily: AppTextStyle.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _taskWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'задача';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'задачи';
    }
    return 'задач';
  }
}

class _RoomPrism extends StatelessWidget {
  const _RoomPrism({
    required this.slot,
    required this.depth,
    required this.hovered,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  final _RoomSlot slot;
  final double depth;
  final bool hovered;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final topColor = hovered ? Color.lerp(slot.floorColor, Colors.white, 0.08)! : slot.floorColor;
    final sideColor = Color.alphaBlend(_dark.withOpacity(0.10), slot.floorColor);
    final frontColor = Color.alphaBlend(_dark.withOpacity(0.16), slot.floorColor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: depth * 0.35,
              top: depth * 0.45,
              right: -depth * 0.35,
              bottom: -depth * 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              right: -depth,
              top: depth * 0.20,
              bottom: 0,
              width: depth,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()..setEntry(1, 0, -0.58),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: sideColor,
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: depth * 0.20,
              right: 0,
              bottom: -depth,
              height: depth,
              child: Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()..setEntry(0, 1, -0.90),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: frontColor,
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: topColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hovered ? Colors.white.withOpacity(0.45) : Colors.white.withOpacity(0.18),
                  width: hovered ? 2 : 1.4,
                ),
              ),
              child: Stack(
                children: [
                  for (var i = 0; i < slot.furniture.length; i++)
                    Align(
                      alignment: slot.furniture[i],
                      child: Transform.rotate(
                        angle: (i.isEven ? -1 : 1) * 0.10 * math.pi,
                        child: Container(
                          width: 16 + i * 3,
                          height: 10 + i * 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withOpacity(0.10)),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 8,
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
