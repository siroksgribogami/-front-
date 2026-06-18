import 'package:flutter/material.dart';
import '../../../core/theme/brand_runtime.dart';
import 'package:provider/provider.dart';

import '../../../config/brand_colors.dart';
import '../../../config/text_theme.dart';
import '../../../config/unity_webgl_config.dart';
import '../../../core/theme/brand_ui.dart';
import '../../../core/theme/map_editor_theme.dart';
import '../../../providers/map_editor_provider.dart';
import '../../tasks/add_task_screen.dart';
import '../unity/hosted_unity_webgl_screen.dart';
import 'furniture_catalog.dart';

const _sage = MapEditorTheme.needles;
const _terra = MapEditorTheme.clay;
const _cream = MapEditorTheme.canvas;
const _dark = MapEditorTheme.text;

class _RoomSlot {
  const _RoomSlot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.floorColor,
    required this.labelDx,
    required this.labelDy,
    required this.badgeDx,
    required this.badgeDy,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Color floorColor;
  final double labelDx;
  final double labelDy;
  final double badgeDx;
  final double badgeDy;
}

class _PlacedFurniture {
  const _PlacedFurniture({
    required this.id,
    required this.template,
    required this.alignment,
    required this.rotationY,
  });

  final String id;
  final FurnitureTemplate template;
  final Alignment alignment;
  final double rotationY;
}

class ApartmentEditorScreen extends StatefulWidget {
  const ApartmentEditorScreen({super.key});

  @override
  State<ApartmentEditorScreen> createState() => _ApartmentEditorScreenState();
}

class _ApartmentEditorScreenState extends State<ApartmentEditorScreen>
    with TickerProviderStateMixin {
  static const _gridW = 18.0;
  static const _gridH = 11.0;

  static const _slots = <_RoomSlot>[
    _RoomSlot(
      left: 0,
      top: 0,
      width: 8,
      height: 6,
      floorColor: Color(0xFFECE5D8),
      labelDx: 0.18,
      labelDy: 0.18,
      badgeDx: 0.70,
      badgeDy: 0.08,
    ),
    _RoomSlot(
      left: 0,
      top: 6,
      width: 6,
      height: 5,
      floorColor: Color(0xFFE4DCCF),
      labelDx: 0.16,
      labelDy: 0.18,
      badgeDx: 0.62,
      badgeDy: 0.14,
    ),
    _RoomSlot(
      left: 8,
      top: 0,
      width: 6,
      height: 6,
      floorColor: Color(0xFFE9E0D2),
      labelDx: 0.14,
      labelDy: 0.20,
      badgeDx: 0.62,
      badgeDy: 0.10,
    ),
    _RoomSlot(
      left: 14,
      top: 0,
      width: 4,
      height: 6,
      floorColor: Color(0xFFDCE4E1),
      labelDx: 0.18,
      labelDy: 0.18,
      badgeDx: 0.58,
      badgeDy: 0.10,
    ),
    _RoomSlot(
      left: 6,
      top: 6,
      width: 5,
      height: 5,
      floorColor: Color(0xFFE2DACE),
      labelDx: 0.18,
      labelDy: 0.18,
      badgeDx: 0.60,
      badgeDy: 0.16,
    ),
    _RoomSlot(
      left: 11,
      top: 6,
      width: 7,
      height: 5,
      floorColor: Color(0xFFE7E0D5),
      labelDx: 0.16,
      labelDy: 0.18,
      badgeDx: 0.65,
      badgeDy: 0.16,
    ),
  ];

  static const _furnitureAnchors = <Alignment>[
    Alignment(-0.45, -0.22),
    Alignment(0.00, -0.18),
    Alignment(0.42, -0.08),
    Alignment(-0.18, 0.20),
    Alignment(0.28, 0.24),
    Alignment(0.00, 0.42),
  ];

  int _activeRoomIndex = 0;
  int? _toolbarMode;
  int _statsTab = 0;
  int _layoutChipIndex = 0;
  int _activeTextureIndex = 0;
  int? _furnitureCategoryIndex;
  String? _selectedFurnitureId;
  int _furnitureIdCounter = 0;

  final Map<int, List<_PlacedFurniture>> _placedFurnitureByRoom = {};

  late final AnimationController _sheetController;
  late final Animation<double> _sheetSlide;

  static const _layoutChips = [
    'ПОЛ',
    'СТЕНЫ',
    'ОКНА',
    'ДВЕРИ',
    'АРКИ',
    'ЛЕСТНИЦЫ'
  ];

  static const _floorMaterials = [
    ('Паркет', Icons.square_rounded),
    ('Линолеум', Icons.square_rounded),
    ('Камень', Icons.square_rounded),
    ('Дерево', Icons.square_rounded),
    ('Ковролин', Icons.square_rounded),
    ('Бетон', Icons.square_rounded),
    ('Плитка', Icons.square_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _sheetSlide = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _openSheet(int mode) {
    setState(() {
      if (_toolbarMode == mode) {
        _toolbarMode = null;
        _sheetController.reverse();
      } else {
        _toolbarMode = mode;
        if (mode != 1) {
          _furnitureCategoryIndex = null;
        }
        _sheetController.forward();
      }
    });
  }

  void _selectRoom(int index) {
    setState(() {
      _activeRoomIndex = index;
      _selectedFurnitureId = null;
    });
  }

  void _addFurniture(FurnitureTemplate template) {
    final currentItems = _placedFurnitureByRoom[_activeRoomIndex] ?? const [];
    final anchor =
        _furnitureAnchors[currentItems.length % _furnitureAnchors.length];
    final item = _PlacedFurniture(
      id: 'f_${_furnitureIdCounter++}',
      template: template,
      alignment: anchor,
      rotationY: currentItems.length.isEven ? 0 : 1.5708,
    );

    setState(() {
      _placedFurnitureByRoom[_activeRoomIndex] = [...currentItems, item];
      _selectedFurnitureId = item.id;
      _toolbarMode = null;
      _furnitureCategoryIndex = null;
    });
    _sheetController.reverse();
  }

  void _deleteSelectedFurniture() {
    final selectedId = _selectedFurnitureId;
    if (selectedId == null) return;

    final currentItems = _placedFurnitureByRoom[_activeRoomIndex] ?? const [];
    setState(() {
      _placedFurnitureByRoom[_activeRoomIndex] = currentItems
          .where((item) => item.id != selectedId)
          .toList(growable: false);
      _selectedFurnitureId = null;
    });
  }

  List<_PlacedFurniture> _currentRoomFurniture() {
    return _placedFurnitureByRoom[_activeRoomIndex] ?? const [];
  }

  void _openHostedUnityWebGl() {
    final raw = UnityWebGlConfig.buildUrl.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не задан URL Unity WebGL (UNITY_WEBGL_BUILD_URL).'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Некорректный URL WebGL билда.')),
      );
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HostedUnityWebGlScreen(uri: uri),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapEditorProvider>();
    final rooms = provider.rooms;

    return Scaffold(
      backgroundColor: BrandRuntime.card,
      body: Column(
        children: [
          _buildHeader(provider),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DesktopGridPainter(),
                              child: Container(color: BrandRuntime.card),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            left: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: BrandRuntime.canvas,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: BrandRuntime.border),
                              ),
                              child: Text(
                                'ПЛАН СВЕРХУ · М 1:50',
                                style: BrandUi.monoLabel(
                                  fontSize: 10,
                                  color: BrandRuntime.ink.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            right: 18,
                            child: Row(
                              children: ['−', '100%', '+'].map((t) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  constraints: const BoxConstraints(minWidth: 36),
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: BrandRuntime.canvas,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: BrandRuntime.border),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    t,
                                    style: BrandUi.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: BrandRuntime.needles,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          ..._buildRoomLabels(constraints, rooms),
                          ..._buildTaskBadges(constraints, rooms),
                          if (_currentRoomFurniture().isNotEmpty)
                            Positioned(
                              left: 12,
                              bottom: 140,
                              child: _buildPlacedFurnitureChips(),
                            ),
                          if (_selectedFurnitureId != null)
                            Positioned(
                              top: 16,
                              left: 0,
                              right: 84,
                              child: Center(child: _buildEditActionsBar()),
                            ),
                          if (_toolbarMode != null) _buildBottomSheet(provider),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 22,
                            child: _buildStatsSheet(provider),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildRightToolbar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(MapEditorProvider provider) {
    final rooms = provider.rooms;
    final activeName =
        _activeRoomIndex < rooms.length ? rooms[_activeRoomIndex].name : 'Объект';

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: BrandRuntime.canvas,
        border: Border(bottom: BorderSide(color: BrandRuntime.border)),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: pochaevsk(fontSize: 22, color: BrandRuntime.needles),
              children: [
                const TextSpan(text: 'При'),
                TextSpan(
                  text: ' деле',
                  style: pochaevsk(fontSize: 22, color: BrandColors.clay),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: BrandRuntime.border,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeName,
                  style: pochaevsk(fontSize: 17, color: BrandRuntime.ink, height: 1),
                ),
                Text(
                  'Хамовники · план объекта · сохранено',
                  style: BrandUi.inter(
                    fontSize: 12,
                    color: BrandRuntime.ink.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          _headerButton('Поделиться', filled: false, onTap: () {}),
          const SizedBox(width: 10),
          Material(
            color: BrandColors.clay,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _openHostedUnityWebGl,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_in_ar_outlined, size: 16, color: BrandColors.onClay),
                    const SizedBox(width: 8),
                    Text(
                      'Открыть 3D',
                      style: BrandUi.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.onClay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const BrandAvatar(name: 'Анна Карелина', size: 38, radius: 11),
        ],
      ),
    );
  }

  Widget _headerButton(String label,
      {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? BrandRuntime.needles : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: BrandRuntime.border, width: 1.5),
        ),
        child: Text(
          label,
          style: BrandUi.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: filled ? BrandColors.onNeedles : BrandRuntime.needles,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoomLabels(
      BoxConstraints constraints, List<MapEditorRoom> rooms) {
    final sceneRect = _computeSceneRect(constraints);
    final count = _slots.length < rooms.length ? _slots.length : rooms.length;
    return List.generate(count, (index) {
      final slot = _slots[index];
      final room = rooms[index];
      final isActive = index == _activeRoomIndex;

      final left = sceneRect.left +
          (slot.left + slot.width * slot.labelDx) / _gridW * sceneRect.width;
      final top = sceneRect.top +
          (slot.top + slot.height * slot.labelDy) / _gridH * sceneRect.height;

      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onTap: () => _selectRoom(index),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 1.0 : 0.65,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? BrandColors.clay.withOpacity(0.12)
                    : BrandRuntime.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? BrandColors.clay : BrandRuntime.border,
                  width: isActive ? 2.5 : 1.6,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.name,
                    style: pochaevsk(
                      fontSize: 14,
                      color: BrandRuntime.needles,
                    ),
                  ),
                  Text(
                    '24.0 м²',
                    style: BrandUi.monoLabel(
                      fontSize: 10,
                      color: BrandRuntime.ink.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildTaskBadges(
      BoxConstraints constraints, List<MapEditorRoom> rooms) {
    final sceneRect = _computeSceneRect(constraints);
    final count = _slots.length < rooms.length ? _slots.length : rooms.length;
    final badges = <Widget>[];

    for (var index = 0; index < count; index++) {
      final slot = _slots[index];
      final room = rooms[index];
      final taskCount = room.taskList.length;
      if (taskCount == 0) continue;

      final left = sceneRect.left +
          (slot.left + slot.width * slot.badgeDx) / _gridW * sceneRect.width;
      final top = sceneRect.top +
          (slot.top + slot.height * slot.badgeDy) / _gridH * sceneRect.height;

      badges.add(
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTap: () {
              _selectRoom(index);
              _openSheet(2);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _terra,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _terra.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$taskCount',
                    style: const TextStyle(
                      fontSize: 11,
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

    return badges;
  }

  _SceneRect _computeSceneRect(BoxConstraints constraints) {
    const sceneAspect = 1.52;
    double sceneW;
    double sceneH;
    if (constraints.maxWidth / constraints.maxHeight > sceneAspect) {
      sceneH = constraints.maxHeight * 0.84;
      sceneW = sceneH * sceneAspect;
    } else {
      sceneW = constraints.maxWidth * 0.84;
      sceneH = sceneW / sceneAspect;
    }

    final left = (constraints.maxWidth - sceneW) / 2;
    final top = (constraints.maxHeight - sceneH) / 2;
    final planW = sceneW * 0.82;
    final planH = sceneH * 0.66;
    final planLeft = left + (sceneW - planW) / 2;
    final planTop = top + sceneH * 0.18;
    return _SceneRect(planLeft, planTop, planW, planH);
  }

  Widget _buildPlacedFurnitureChips() {
    final current = _currentRoomFurniture();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: current.map((item) {
          final active = _selectedFurnitureId == item.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedFurnitureId = item.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? _sage.withOpacity(0.92)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: active ? _sage : _sage.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.template.emoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    item.template.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _dark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildEditActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionBtn(
            icon: Icons.undo_rounded,
            color: const Color(0xFF7A8A7C),
            onTap: () {},
          ),
          _actionBtn(
            icon: Icons.redo_rounded,
            color: const Color(0xFF7A8A7C),
            onTap: () {},
          ),
          Container(
              width: 1,
              height: 24,
              color: const Color(0xFFD8D4CC),
              margin: const EdgeInsets.symmetric(horizontal: 4)),
          _actionBtn(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFC06060),
            onTap: _deleteSelectedFurniture,
          ),
          Container(
              width: 1,
              height: 24,
              color: const Color(0xFFD8D4CC),
              margin: const EdgeInsets.symmetric(horizontal: 4)),
          GestureDetector(
            onTap: () => setState(() => _selectedFurnitureId = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _sage,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Готово',
                style: TextStyle(
                  fontFamily: AppTextStyle.uiFontFamily,
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildRightToolbar() {
    return Container(
      width: 84,
      color: BrandColors.needlesDeep,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          _DesktopTool(
            label: 'Стены',
            icon: Icons.square_outlined,
            active: _toolbarMode == 0,
            onTap: () => _openSheet(0),
          ),
          _DesktopTool(
            label: 'Двери',
            icon: Icons.door_front_door_outlined,
            active: _toolbarMode == 1,
            onTap: () => _openSheet(1),
          ),
          _DesktopTool(
            label: 'Окна',
            icon: Icons.window_outlined,
            active: false,
            onTap: () {},
          ),
          _DesktopTool(
            label: 'Мебель',
            icon: Icons.weekend_outlined,
            active: _toolbarMode == 1,
            onTap: () => _openSheet(1),
          ),
          _DesktopTool(
            label: 'Размер',
            icon: Icons.straighten,
            active: false,
            onTap: () {},
          ),
          const Spacer(),
          _DesktopTool(
            label: 'Задачи',
            icon: Icons.check_circle_outline,
            active: _toolbarMode == 2,
            onTap: () => _openSheet(2),
          ),
          _DesktopTool(
            label: 'ИИ',
            icon: Icons.auto_awesome_outlined,
            active: false,
            onTap: () {},
            accentIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSheet(MapEditorProvider provider) {
    const tabs = ['Планировка', 'Мебель', 'Задачи'];
    const stats = [
      ('Комнат', '5'),
      ('Общая площадь', '66.7 м²'),
      ('Жилая', '52.6 м²'),
      ('Мебель', '14 шт'),
      ('Задачи ремонта', '5 активных'),
      ('Смета', '1,18 млн ₽'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: BrandRuntime.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandRuntime.border),
        boxShadow: [
          BoxShadow(
            color: BrandColors.needlesDeep.withOpacity(0.12),
            blurRadius: 50,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _statsTab = i),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 13, 22, 13),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _statsTab == i
                              ? BrandColors.clay
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tabs[i],
                          style: BrandUi.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _statsTab == i
                                ? BrandRuntime.ink
                                : BrandRuntime.ink.withOpacity(0.55),
                          ),
                        ),
                        if (i == 2) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.sandstone,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${provider.rooms.fold<int>(0, (s, r) => s + r.taskList.length)}',
                              style: BrandUi.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.surik,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: BrandRuntime.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.support_agent, size: 16, color: BrandRuntime.needles),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ИИ-прораб готов помочь',
                      style: BrandUi.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: BrandRuntime.needles,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 1, color: BrandRuntime.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: BrandRuntime.border,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats[i].$1.toUpperCase(),
                          style: BrandUi.inter(
                            fontSize: 11,
                            color: BrandRuntime.ink.withOpacity(0.4),
                          ).copyWith(letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats[i].$2,
                          style: pochaevsk(
                            fontSize: 22,
                            color: i == 5 ? BrandColors.clay : BrandRuntime.needles,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(MapEditorProvider provider) {
    return AnimatedBuilder(
      animation: _sheetSlide,
      builder: (context, child) {
        if (_sheetSlide.value == 0 && _toolbarMode == null) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: 0,
          right: 84,
          bottom: 130,
          height: 280 * _sheetSlide.value,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1EA),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _toolbarMode == 0
                        ? _buildLayoutSheet()
                        : _toolbarMode == 1
                            ? _buildFurnitureSheet()
                            : _toolbarMode == 2
                                ? _buildTasksSheet(provider)
                                : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayoutSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _layoutChips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isActive = index == _layoutChipIndex;
              return GestureDetector(
                onTap: () => setState(() => _layoutChipIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _terra : const Color(0xFFEEF1EE),
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? null
                        : Border.all(color: const Color(0xFFD0D8D0)),
                  ),
                  child: Center(
                    child: Text(
                      _layoutChips[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive ? Colors.white : _sage,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: _floorMaterials.length,
            itemBuilder: (context, index) {
              final (name, _) = _floorMaterials[index];
              final isActive = index == _activeTextureIndex;
              return GestureDetector(
                onTap: () => setState(() => _activeTextureIndex = index),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? _terra : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.texture_rounded,
                            color:
                                Colors.white.withOpacity(isActive ? 0.6 : 0.4),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? _dark : _dark.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFurnitureSheet() {
    if (_furnitureCategoryIndex != null) {
      return _buildFurnitureList(furnitureCatalog[_furnitureCategoryIndex!]);
    }
    return _buildFurnitureCategoryGrid();
  }

  Widget _buildFurnitureCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: furnitureCatalog.length,
      itemBuilder: (context, index) {
        final cat = furnitureCatalog[index];
        return GestureDetector(
          onTap: () => setState(() => _furnitureCategoryIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDE4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8D4CC), width: 1.5),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFurnitureList(FurnitureCategory category) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _furnitureCategoryIndex = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: _dark),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${category.emoji} ${category.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
              ),
              const Spacer(),
              Text(
                'Добавление в ${context.read<MapEditorProvider>().rooms[_activeRoomIndex].name}',
                style: TextStyle(
                  fontSize: 12,
                  color: _dark.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: category.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = category.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                            ),
                          ),
                          Text(
                            item.dimensions,
                            style: TextStyle(
                              fontSize: 12,
                              color: _dark.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addFurniture(item),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSheet(MapEditorProvider provider) {
    final rooms = provider.rooms;
    if (_activeRoomIndex >= rooms.length) return const SizedBox.shrink();
    final room = rooms[_activeRoomIndex];
    final tasks = room.taskList;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(room.icon, color: _sage, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Задачи — ${room.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _sage, size: 24),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'Задач пока нет',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dark.withOpacity(0.65),
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isUrgent = index == 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: isUrgent ? _terra : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank_rounded,
                              size: 20, color: _sage),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task,
                              style:
                                  const TextStyle(fontSize: 14, color: _dark),
                            ),
                          ),
                          Text(
                            room.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: _dark.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SceneRect {
  const _SceneRect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;
}

class _DesktopGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 31.0;
    final paint = Paint()..color = BrandRuntime.needles.withOpacity(0.045);
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DesktopTool extends StatelessWidget {
  const _DesktopTool({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.accentIcon = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? BrandColors.onClay
        : BrandColors.onNeedles.withOpacity(0.8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: active ? BrandColors.clay : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: accentIcon && !active ? BrandColors.dawn : fg,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: BrandUi.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
