import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/room_layout.dart';
import 'isometric_painter.dart';
import 'furniture_catalog_sheet.dart';

// ============================================================
//  ЭКРАН РЕДАКТОРА КОМНАТЫ (Sims-style 2.5D)
// ============================================================

class RoomEditorScreen extends StatefulWidget {
  final String roomName;

  const RoomEditorScreen({super.key, required this.roomName});

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen>
    with TickerProviderStateMixin {
  late RoomLayout _room;
  PlacedFurniture? _selectedFurniture;
  FurnitureTemplate? _pendingTemplate; // шаблон, который выбран для размещения

  // Режимы панели
  _PanelMode _panelMode = _PanelMode.none;

  // Анимации появления нижней панели
  late AnimationController _panelAnim;
  late Animation<double> _panelSlide;

  int _instanceCounter = 0;

  @override
  void initState() {
    super.initState();
    _room = _buildDefaultRoom(widget.roomName);

    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _panelSlide = CurvedAnimation(parent: _panelAnim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _panelAnim.dispose();
    super.dispose();
  }

  // ── Создаём дефолтную планировку ──────────────────────────
  RoomLayout _buildDefaultRoom(String name) {
    final defaults = <String, List<PlacedFurniture>>{
      'Гостиная': [
        PlacedFurniture(
          instanceId: 'sofa_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'sofa_2'),
          gridX: 1, gridY: 1,
        ),
        PlacedFurniture(
          instanceId: 'tv_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'tv'),
          gridX: 3, gridY: 4,
          rotation: 180,
        ),
        PlacedFurniture(
          instanceId: 'plant_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'plant_big'),
          gridX: 6, gridY: 0,
        ),
      ],
      'Спальня': [
        PlacedFurniture(
          instanceId: 'bed_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'bed_double'),
          gridX: 2, gridY: 1,
        ),
        PlacedFurniture(
          instanceId: 'wardrobe_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'wardrobe'),
          gridX: 5, gridY: 0,
        ),
      ],
      'Кухня': [
        PlacedFurniture(
          instanceId: 'table_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'dining_table'),
          gridX: 3, gridY: 2,
        ),
        PlacedFurniture(
          instanceId: 'fridge_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'fridge'),
          gridX: 1, gridY: 0,
        ),
      ],
      'Ванная': [
        PlacedFurniture(
          instanceId: 'bath_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'bathtub'),
          gridX: 0, gridY: 1,
        ),
        PlacedFurniture(
          instanceId: 'toilet_default',
          template: kFurnitureCatalog.firstWhere((t) => t.id == 'toilet'),
          gridX: 3, gridY: 0,
        ),
      ],
    };

    return RoomLayout(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      furniture: defaults[name] ?? [],
    );
  }

  // ── Управление панелью ────────────────────────────────────
  void _showPanel(_PanelMode mode) {
    setState(() => _panelMode = mode);
    _panelAnim.forward(from: 0);
  }

  void _hidePanel() {
    _panelAnim.reverse().then((_) {
      if (mounted) setState(() => _panelMode = _PanelMode.none);
    });
  }

  // ── Мебель ───────────────────────────────────────────────
  void _startPlacing(FurnitureTemplate template) {
    setState(() {
      _pendingTemplate = template;
      _selectedFurniture = null;
    });
    _hidePanel();
  }

  void _placeFurniture(int gx, int gy) {
    if (_pendingTemplate == null) return;
    _instanceCounter++;
    setState(() {
      _room.furniture.add(PlacedFurniture(
        instanceId: 'item_$_instanceCounter',
        template: _pendingTemplate!,
        gridX: gx,
        gridY: gy,
      ));
      _pendingTemplate = null;
    });
  }

  void _selectFurniture(PlacedFurniture item) {
    setState(() {
      _selectedFurniture = item;
      _pendingTemplate = null;
    });
  }

  void _rotateFurniture() {
    if (_selectedFurniture == null) return;
    setState(() {
      final idx = _room.furniture.indexWhere(
          (f) => f.instanceId == _selectedFurniture!.instanceId);
      if (idx == -1) return;
      final newRot = (_room.furniture[idx].rotation + 90) % 360;
      _room.furniture[idx] = _room.furniture[idx].copyWith(rotation: newRot);
      _selectedFurniture = _room.furniture[idx];
    });
  }

  void _deleteFurniture() {
    if (_selectedFurniture == null) return;
    setState(() {
      _room.furniture.removeWhere(
          (f) => f.instanceId == _selectedFurniture!.instanceId);
      _selectedFurniture = null;
    });
  }

  void _changeFurnitureColor(Color color) {
    if (_selectedFurniture == null) return;
    setState(() {
      final idx = _room.furniture.indexWhere(
          (f) => f.instanceId == _selectedFurniture!.instanceId);
      if (idx == -1) return;
      _room.furniture[idx] = _room.furniture[idx].copyWith(color: color);
      _selectedFurniture = _room.furniture[idx];
    });
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // ── Изометрический вид ──────────────────────────
          Positioned.fill(
            bottom: 72,
            child: IsometricRoomView(
              room: _room,
              selectedFurniture: _selectedFurniture,
              pendingPlacement: _pendingTemplate,
              onFurnitureSelected: _selectFurniture,
              onTileTap: (cell) {
                if (_pendingTemplate != null) {
                  _placeFurniture(cell.$1, cell.$2);
                } else {
                  setState(() => _selectedFurniture = null);
                }
              },
            ),
          ),

          // ── Верхний бар ─────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopBar(
              roomName: _room.name,
              onBack: () {
                if (_pendingTemplate != null) {
                  setState(() => _pendingTemplate = null);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),

          // ── Подсказка при размещении ────────────────────
          if (_pendingTemplate != null)
            Positioned(
              top: 80,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Нажмите на клетку, чтобы поставить «${_pendingTemplate!.name}»',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),

          // ── Панель выбранной мебели ──────────────────────
          if (_selectedFurniture != null)
            Positioned(
              bottom: 80, left: 16, right: 16,
              child: _SelectedFurniturePanel(
                item: _selectedFurniture!,
                onRotate: _rotateFurniture,
                onDelete: _deleteFurniture,
                onColorChange: _changeFurnitureColor,
                onClose: () => setState(() => _selectedFurniture = null),
              ),
            ),

          // ── Нижний тулбар ───────────────────────────────
          if (_selectedFurniture == null && _pendingTemplate == null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _BottomToolbar(
                activeMode: _panelMode,
                onFurniture: () => _panelMode == _PanelMode.furniture
                    ? _hidePanel()
                    : _showPanel(_PanelMode.furniture),
                onFloor: () => _panelMode == _PanelMode.floor
                    ? _hidePanel()
                    : _showPanel(_PanelMode.floor),
                onWalls: () => _panelMode == _PanelMode.walls
                    ? _hidePanel()
                    : _showPanel(_PanelMode.walls),
              ),
            ),

          // ── Всплывающие панели ───────────────────────────
          if (_panelMode == _PanelMode.floor)
            _SlidingPanel(
              animation: _panelSlide,
              onClose: _hidePanel,
              title: 'Покрытие пола',
              child: _MaterialPickerGrid(
                materials: kFloorMaterials,
                selected: _room.floorMaterial,
                onSelected: (m) => setState(() => _room.floorMaterial = m),
              ),
            ),

          if (_panelMode == _PanelMode.walls)
            _SlidingPanel(
              animation: _panelSlide,
              onClose: _hidePanel,
              title: 'Обои / цвет стен',
              child: _MaterialPickerGrid(
                materials: kWallMaterials,
                selected: _room.wallMaterial,
                onSelected: (m) => setState(() => _room.wallMaterial = m),
              ),
            ),

          if (_panelMode == _PanelMode.furniture)
            _SlidingPanel(
              animation: _panelSlide,
              onClose: _hidePanel,
              title: 'Каталог мебели',
              tall: true,
              child: FurnitureCatalogContent(
                onSelect: _startPlacing,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Вспомогательные виджеты
// ─────────────────────────────────────────────────────────────

enum _PanelMode { none, furniture, floor, walls }

// ── Верхний бар ────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String roomName;
  final VoidCallback onBack;
  const _TopBar({required this.roomName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            roomName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Gropled',
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Иконка помощи
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.help_outline_rounded,
                size: 18, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

// ── Нижний тулбар ──────────────────────────────────────────
class _BottomToolbar extends StatelessWidget {
  final _PanelMode activeMode;
  final VoidCallback onFurniture;
  final VoidCallback onFloor;
  final VoidCallback onWalls;

  const _BottomToolbar({
    required this.activeMode,
    required this.onFurniture,
    required this.onFloor,
    required this.onWalls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ToolBtn(
            icon: Icons.chair_alt_rounded,
            label: 'Мебель',
            active: activeMode == _PanelMode.furniture,
            onTap: onFurniture,
          ),
          _ToolBtn(
            icon: Icons.square_foot_rounded,
            label: 'Пол',
            active: activeMode == _PanelMode.floor,
            onTap: onFloor,
          ),
          _ToolBtn(
            icon: Icons.format_paint_rounded,
            label: 'Стены',
            active: activeMode == _PanelMode.walls,
            onTap: onWalls,
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: active ? AppTheme.primaryColor : AppTheme.warmGrey),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppTheme.primaryColor : AppTheme.warmGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Панель выбранной мебели ─────────────────────────────────
class _SelectedFurniturePanel extends StatelessWidget {
  final PlacedFurniture item;
  final VoidCallback onRotate;
  final VoidCallback onDelete;
  final ValueChanged<Color> onColorChange;
  final VoidCallback onClose;

  const _SelectedFurniturePanel({
    required this.item,
    required this.onRotate,
    required this.onDelete,
    required this.onColorChange,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = item.template.availableColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Row(
            children: [
              Text(item.template.emoji,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.template.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppTheme.warmGrey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Кнопки действий
          Row(
            children: [
              _ActionBtn(
                icon: Icons.rotate_right_rounded,
                label: 'Повернуть',
                onTap: onRotate,
              ),
              const SizedBox(width: 10),
              _ActionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Удалить',
                onTap: onDelete,
                danger: true,
              ),
            ],
          ),
          // Выбор цвета (если есть варианты)
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Цвет',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 8),
            Row(
              children: colors.map((c) {
                final isSelected = (item.color.value == c.value);
                return GestureDetector(
                  onTap: () => onColorChange(c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.primaryColor, width: 3)
                          : Border.all(
                              color: Colors.black.withOpacity(0.08), width: 1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.errorColor : AppTheme.primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Скользящая панель снизу ─────────────────────────────────
class _SlidingPanel extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onClose;
  final String title;
  final Widget child;
  final bool tall;

  const _SlidingPanel({
    required this.animation,
    required this.onClose,
    required this.title,
    required this.child,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: animation,
        builder: (ctx, ch) => Transform.translate(
          offset: Offset(0, (1 - animation.value) * 400),
          child: ch,
        ),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: tall ? 380 : 280),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 20)],
          ),
          child: Column(
            children: [
              // Ручка + заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close_rounded,
                          size: 20, color: AppTheme.warmGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Выбор материала (пол/стены) ─────────────────────────────
class _MaterialPickerGrid extends StatelessWidget {
  final List<SurfaceMaterial> materials;
  final SurfaceMaterial selected;
  final ValueChanged<SurfaceMaterial> onSelected;

  const _MaterialPickerGrid({
    required this.materials,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: materials.length,
      itemBuilder: (ctx, i) {
        final m = materials[i];
        final isSelected = m.id == selected.id;
        return GestureDetector(
          onTap: () => onSelected(m),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: m.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check_rounded,
                              color: Colors.white, size: 20))
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
