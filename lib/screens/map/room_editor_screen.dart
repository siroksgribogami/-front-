import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../models/room_layout.dart';
import 'isometric_painter.dart';

// ============================================================
//  ЭКРАН 3D-РЕДАКТОРА КОМНАТЫ
//  - Боковая панель инструментов
//  - Квадратные кнопки выбора комнат
//  - Кнопка «Готово» при изменениях
//  - Подтверждение нажатием вне панели
//  - Полный набор типов комнат
//  - Скруглённый дизайн
// ============================================================

/// Все доступные типы комнат
const List<Map<String, dynamic>> kAllRoomTypes = [
  {'name': 'Гостиная',    'icon': Icons.weekend,           'gridW': 8, 'gridH': 6},
  {'name': 'Спальня',     'icon': Icons.bed,               'gridW': 6, 'gridH': 5},
  {'name': 'Кухня',       'icon': Icons.kitchen,           'gridW': 6, 'gridH': 5},
  {'name': 'Ванная',      'icon': Icons.bathtub,           'gridW': 4, 'gridH': 4},
  {'name': 'Кабинет',     'icon': Icons.computer,          'gridW': 5, 'gridH': 4},
  {'name': 'Детская',     'icon': Icons.child_care,        'gridW': 6, 'gridH': 5},
  {'name': 'Прихожая',    'icon': Icons.door_front_door,   'gridW': 4, 'gridH': 3},
  {'name': 'Балкон',      'icon': Icons.balcony,           'gridW': 5, 'gridH': 2},
  {'name': 'Гардероб',    'icon': Icons.checkroom,         'gridW': 3, 'gridH': 3},
  {'name': 'Столовая',    'icon': Icons.dining,            'gridW': 6, 'gridH': 5},
  {'name': 'Терраса',     'icon': Icons.deck,              'gridW': 7, 'gridH': 4},
  {'name': 'Коридор',     'icon': Icons.sensor_door,       'gridW': 6, 'gridH': 2},
  {'name': 'Кладовая',    'icon': Icons.inventory_2,       'gridW': 3, 'gridH': 2},
  {'name': 'Лоджия',      'icon': Icons.window,            'gridW': 5, 'gridH': 2},
  {'name': 'Гостевая',    'icon': Icons.hotel,             'gridW': 5, 'gridH': 5},
  {'name': 'Игровая',     'icon': Icons.sports_esports,    'gridW': 6, 'gridH': 5},
];

/// Режим редактирования
enum _EditMode { none, furniture, floor, walls, color }

class RoomEditorScreen extends StatefulWidget {
  final String roomName;
  const RoomEditorScreen({super.key, required this.roomName});

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen>
    with SingleTickerProviderStateMixin {
  late RoomLayout _room;
  PlacedFurniture? _selectedFurniture;
  FurnitureTemplate? _pendingPlacement;
  _EditMode _editMode = _EditMode.none;
  bool _hasUnsavedChanges = false;
  int _selectedRoomIndex = 0;

  // Для анимации панели
  late AnimationController _panelController;
  late Animation<double> _panelSlide;

  @override
  void initState() {
    super.initState();

    // Ищем индекс текущей комнаты
    _selectedRoomIndex = kAllRoomTypes
        .indexWhere((r) => r['name'] == widget.roomName);
    if (_selectedRoomIndex < 0) _selectedRoomIndex = 0;

    final rt = kAllRoomTypes[_selectedRoomIndex];
    _room = RoomLayout(
      id: 'room_${widget.roomName}',
      name: widget.roomName,
      gridWidth: rt['gridW'] as int,
      gridHeight: rt['gridH'] as int,
    );

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  // ── Переключение комнаты ──────────────────────────────
  void _switchRoom(int index) {
    final rt = kAllRoomTypes[index];
    setState(() {
      _selectedRoomIndex = index;
      _selectedFurniture = null;
      _pendingPlacement = null;
      _editMode = _EditMode.none;
      _room = RoomLayout(
        id: 'room_${rt['name']}',
        name: rt['name'] as String,
        gridWidth: rt['gridW'] as int,
        gridHeight: rt['gridH'] as int,
      );
    });
  }

  // ── Открыть / закрыть панель режима ──────────────────
  void _openEditMode(_EditMode mode) {
    setState(() => _editMode = mode);
    _panelController.forward();
  }

  void _closeEditMode() {
    _panelController.reverse().then((_) {
      if (mounted) setState(() => _editMode = _EditMode.none);
    });
  }

  // ── Подтвердить изменения ─────────────────────────────
  void _confirmChanges() {
    setState(() => _hasUnsavedChanges = false);
    _closeEditMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Изменения сохранены'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ── Мебель: разместить ─────────────────────────────────
  void _placeFurniture(FurnitureTemplate template) {
    setState(() {
      _pendingPlacement = template;
      _hasUnsavedChanges = true;
    });
  }

  void _onTileTap((int, int) cell) {
    if (_pendingPlacement != null) {
      final (gx, gy) = cell;
      setState(() {
        _room.furniture.add(PlacedFurniture(
          instanceId: '${_pendingPlacement!.id}_${DateTime.now().millisecondsSinceEpoch}',
          template: _pendingPlacement!,
          gridX: gx,
          gridY: gy,
        ));
        _pendingPlacement = null;
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onFurnitureSelected(PlacedFurniture f) {
    setState(() => _selectedFurniture = f);
  }

  void _deleteFurniture() {
    if (_selectedFurniture == null) return;
    setState(() {
      _room.furniture.removeWhere(
          (f) => f.instanceId == _selectedFurniture!.instanceId);
      _selectedFurniture = null;
      _hasUnsavedChanges = true;
    });
  }

  void _rotateFurniture() {
    if (_selectedFurniture == null) return;
    setState(() {
      _selectedFurniture!.rotation =
          (_selectedFurniture!.rotation + 90) % 360;
      _hasUnsavedChanges = true;
    });
  }

  void _changeFloor(SurfaceMaterial m) {
    setState(() {
      _room.floorMaterial = m;
      _hasUnsavedChanges = true;
    });
  }

  void _changeWall(SurfaceMaterial m) {
    setState(() {
      _room.wallMaterial = m;
      _hasUnsavedChanges = true;
    });
  }

  void _changeFurnitureColor(Color c) {
    if (_selectedFurniture == null) return;
    setState(() {
      _selectedFurniture!.color = c;
      _hasUnsavedChanges = true;
    });
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Верхний заголовок ──────────────────────
            _buildHeader(),

            // ── Квадратные кнопки комнат (горизонтальный скролл) ─
            _buildRoomSelector(),

            const SizedBox(height: 6),

            // ── Основная область: изометрия + боковая панель ─
            Expanded(
              child: Stack(
                children: [
                  // Нажатие вне панели → подтверждение
                  GestureDetector(
                    onTap: () {
                      if (_editMode != _EditMode.none) {
                        _confirmChanges();
                      } else if (_selectedFurniture != null) {
                        setState(() => _selectedFurniture = null);
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: _buildIsometricView(),
                    ),
                  ),

                  // ── Выдвижная панель контента ──────
                  if (_editMode != _EditMode.none)
                    Positioned(
                      top: 8,
                      bottom: 8,
                      right: 66,
                      child: AnimatedBuilder(
                        animation: _panelSlide,
                        builder: (ctx, child) {
                          return Transform.translate(
                            offset: Offset(
                              200 * (1 - _panelSlide.value), 0),
                            child: Opacity(
                              opacity: _panelSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: _EditContentPanel(
                          mode: _editMode,
                          selectedFurniture: _selectedFurniture,
                          onFurnitureSelect: _placeFurniture,
                          onFloorSelect: _changeFloor,
                          onWallSelect: _changeWall,
                          onColorSelect: _changeFurnitureColor,
                          onClose: _confirmChanges,
                        ),
                      ),
                    ),

                  // ── Боковая панель справа ──────────
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: _buildSidePanel(),
                  ),

                  // ── Плавающие кнопки действий над мебелью ─
                  if (_selectedFurniture != null && _editMode == _EditMode.none)
                    _buildFurnitureActions(),

                  // ── Кнопка «Готово» при изменениях ─
                  if (_hasUnsavedChanges)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 80,
                      child: _buildDoneButton(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ЗАГОЛОВОК ──────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _room.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyle.fontFamily,
                    color: AppTheme.textPrimary,
                    height: AppTextStyle.defaultHeight,
                    leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                  ),
                ),
                Text(
                  '${_room.gridWidth}×${_room.gridHeight} клеток',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Размер комнаты +-
          _miniAction(Icons.remove, () {
            if (_room.gridWidth > 3 || _room.gridHeight > 3) {
              setState(() {
                if (_room.gridWidth > 3) _room.gridWidth--;
                if (_room.gridHeight > 3) _room.gridHeight--;
                _hasUnsavedChanges = true;
              });
            }
          }),
          const SizedBox(width: 6),
          _miniAction(Icons.add, () {
            setState(() {
              _room.gridWidth++;
              _room.gridHeight++;
              _hasUnsavedChanges = true;
            });
          }),
        ],
      ),
    );
  }

  Widget _miniAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: AppTheme.primaryColor),
      ),
    );
  }

  // ── КВАДРАТНЫЕ КНОПКИ КОМНАТ ─────────────────────────
  Widget _buildRoomSelector() {
    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kAllRoomTypes.length,
        itemBuilder: (ctx, i) {
          final rt = kAllRoomTypes[i];
          final isActive = i == _selectedRoomIndex;
          return GestureDetector(
            onTap: () => _switchRoom(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    rt['icon'] as IconData,
                    size: 20,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rt['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ИЗОМЕТРИЧЕСКИЙ ВИД ────────────────────────────────
  Widget _buildIsometricView() {
    return Padding(
      padding: const EdgeInsets.only(right: 64), // место для боковой панели
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IsometricRoomView(
          room: _room,
          selectedFurniture: _selectedFurniture,
          pendingPlacement: _pendingPlacement,
          onFurnitureSelected: _onFurnitureSelected,
          onTileTap: _onTileTap,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  БОКОВАЯ ПАНЕЛЬ (справа)
  // ══════════════════════════════════════════════════════
  Widget _buildSidePanel() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          bottomLeft: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _sideButton(
            icon: Icons.weekend_outlined,
            label: 'Мебель',
            active: _editMode == _EditMode.furniture,
            onTap: () {
              if (_editMode == _EditMode.furniture) {
                _confirmChanges();
              } else {
                _openEditMode(_EditMode.furniture);
              }
            },
          ),
          _sideButton(
            icon: Icons.grid_view_rounded,
            label: 'Пол',
            active: _editMode == _EditMode.floor,
            onTap: () {
              if (_editMode == _EditMode.floor) {
                _confirmChanges();
              } else {
                _openEditMode(_EditMode.floor);
              }
            },
          ),
          _sideButton(
            icon: Icons.wallpaper_rounded,
            label: 'Стены',
            active: _editMode == _EditMode.walls,
            onTap: () {
              if (_editMode == _EditMode.walls) {
                _confirmChanges();
              } else {
                _openEditMode(_EditMode.walls);
              }
            },
          ),
          _sideButton(
            icon: Icons.palette_outlined,
            label: 'Цвет',
            active: _editMode == _EditMode.color,
            onTap: () {
              if (_selectedFurniture != null) {
                if (_editMode == _EditMode.color) {
                  _confirmChanges();
                } else {
                  _openEditMode(_EditMode.color);
                }
              }
            },
          ),
          const Spacer(),
          // Удалить выбранную мебель
          if (_selectedFurniture != null)
            _sideButton(
              icon: Icons.delete_outline_rounded,
              label: 'Удалить',
              active: false,
              isDestructive: true,
              onTap: _deleteFurniture,
            ),
          if (_selectedFurniture != null)
            _sideButton(
              icon: Icons.rotate_right_rounded,
              label: 'Поворот',
              active: false,
              onTap: _rotateFurniture,
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? AppTheme.errorColor
        : active
            ? AppTheme.primaryColor
            : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ДЕЙСТВИЯ НАД МЕБЕЛЬЮ (плавающие) ───────────────
  Widget _buildFurnitureActions() {
    return Positioned(
      bottom: _hasUnsavedChanges ? 70 : 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedFurniture!.template.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedFurniture!.template.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            _actionChip(Icons.rotate_right_rounded, _rotateFurniture),
            const SizedBox(width: 4),
            _actionChip(Icons.palette_outlined, () {
              _openEditMode(_EditMode.color);
            }),
            const SizedBox(width: 4),
            _actionChip(Icons.delete_outline_rounded, _deleteFurniture,
                isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
      ),
    );
  }

  // ── КНОПКА «ГОТОВО» ────────────────────────────────────
  Widget _buildDoneButton() {
    return GestureDetector(
      onTap: _confirmChanges,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Готово',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  ПЕРЕОПРЕДЕЛЁННЫЙ build С ПАНЕЛЯМИ
  // ══════════════════════════════════════════════════════
  // (используем overlay-подход вместо отдельных экранов)

  // Переопределим build так, чтобы выдвижные панели
  // рендерились в Stack поверх isometric view.
  // Уже учтено выше через _editMode.

  // Но нужно добавить сами панели в Stack!

  // → Обновляем основной build:
  // Заменяем метод build() на _buildBody() и добавляем панели.

  // Однако, чтобы не дублировать, перенесём логику панелей
  // в отдельные методы и вставим в Stack.

}

// ══════════════════════════════════════════════════════════
//  ВИДЖЕТ ВЫДВИЖНОЙ ПАНЕЛИ (слева от боковой панели)
// ══════════════════════════════════════════════════════════

/// Дополнительная панель контента — мебель / пол / стены / цвет
class _EditContentPanel extends StatelessWidget {
  final _EditMode mode;
  final PlacedFurniture? selectedFurniture;
  final ValueChanged<FurnitureTemplate> onFurnitureSelect;
  final ValueChanged<SurfaceMaterial> onFloorSelect;
  final ValueChanged<SurfaceMaterial> onWallSelect;
  final ValueChanged<Color> onColorSelect;
  final VoidCallback onClose;

  const _EditContentPanel({
    required this.mode,
    required this.selectedFurniture,
    required this.onFurnitureSelect,
    required this.onFloorSelect,
    required this.onWallSelect,
    required this.onColorSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildPanelHeader(context),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildPanelHeader(BuildContext context) {
    String title;
    switch (mode) {
      case _EditMode.furniture:
        title = 'Мебель';
      case _EditMode.floor:
        title = 'Пол';
      case _EditMode.walls:
        title = 'Стены';
      case _EditMode.color:
        title = 'Цвет';
      case _EditMode.none:
        title = '';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: AppTextStyle.fontFamily,
              color: AppTheme.textPrimary,
              height: AppTextStyle.defaultHeight,
              leadingDistribution: AppTextStyle.defaultLeadingDistribution,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 14, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (mode) {
      case _EditMode.furniture:
        return _FurnitureMiniGrid(onSelect: onFurnitureSelect);
      case _EditMode.floor:
        return _MaterialGrid(
          materials: kFloorMaterials,
          onSelect: onFloorSelect,
        );
      case _EditMode.walls:
        return _MaterialGrid(
          materials: kWallMaterials,
          onSelect: onWallSelect,
        );
      case _EditMode.color:
        return _ColorGrid(
          furniture: selectedFurniture,
          onSelect: onColorSelect,
        );
      case _EditMode.none:
        return const SizedBox.shrink();
    }
  }
}

// ── Мини-сетка мебели (квадратные маленькие плитки) ──────
class _FurnitureMiniGrid extends StatefulWidget {
  final ValueChanged<FurnitureTemplate> onSelect;
  const _FurnitureMiniGrid({required this.onSelect});

  @override
  State<_FurnitureMiniGrid> createState() => _FurnitureMiniGridState();
}

class _FurnitureMiniGridState extends State<_FurnitureMiniGrid> {
  FurnitureCategory? _filter;

  List<FurnitureTemplate> get _items {
    if (_filter == null) return kFurnitureCatalog;
    return kFurnitureCatalog.where((t) => t.category == _filter).toList();
  }

  static const _catIcons = {
    FurnitureCategory.seating: ('🛋️', 'Диваны'),
    FurnitureCategory.tables: ('🪑', 'Столы'),
    FurnitureCategory.beds: ('🛏️', 'Кровати'),
    FurnitureCategory.storage: ('🚪', 'Шкафы'),
    FurnitureCategory.appliances: ('📺', 'Техника'),
    FurnitureCategory.decor: ('🌿', 'Декор'),
    FurnitureCategory.bathroom: ('🛁', 'Ванная'),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Фильтр категорий — маленький горизонтальный скролл
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              _miniCatChip('✨', 'Все', _filter == null, () {
                setState(() => _filter = null);
              }),
              ...FurnitureCategory.values.map((cat) {
                final (emoji, label) = _catIcons[cat]!;
                return _miniCatChip(emoji, label, _filter == cat, () {
                  setState(() => _filter = cat);
                });
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Сетка — 3 колонки, квадратные маленькие
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0, // квадрат
            ),
            itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final item = _items[i];
              return GestureDetector(
                onTap: () => widget.onSelect(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: item.baseColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.baseColor.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _miniCatChip(
      String emoji, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Сетка материалов (пол / стены) ──────────────────────
class _MaterialGrid extends StatelessWidget {
  final List<SurfaceMaterial> materials;
  final ValueChanged<SurfaceMaterial> onSelect;

  const _MaterialGrid({required this.materials, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: materials.length,
      itemBuilder: (ctx, i) {
        final m = materials[i];
        return GestureDetector(
          onTap: () => onSelect(m),
          child: Container(
            decoration: BoxDecoration(
              color: m.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: m.color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                m.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: m.color.computeLuminance() > 0.5
                      ? AppTheme.textPrimary
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Сетка цветов (для мебели) ────────────────────────────
class _ColorGrid extends StatelessWidget {
  final PlacedFurniture? furniture;
  final ValueChanged<Color> onSelect;

  const _ColorGrid({required this.furniture, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = furniture?.template.availableColors ?? [];
    final allColors = [
      ...colors,
      const Color(0xFF8D9B8A),
      const Color(0xFFB5896A),
      const Color(0xFF5A6B7F),
      const Color(0xFFE8DFCC),
      const Color(0xFF3A3A3A),
      const Color(0xFFD4956A),
      const Color(0xFFEEEEEE),
      const Color(0xFF6C8671),
      const Color(0xFFBCA882),
    ];

    // Уникальные цвета
    final unique = <Color>[];
    for (final c in allColors) {
      if (!unique.any((u) => u.value == c.value)) unique.add(c);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: unique.length,
      itemBuilder: (ctx, i) {
        final c = unique[i];
        final isSelected =
            furniture != null && furniture!.color.value == c.value;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: Container(
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentColor
                    : Colors.black.withOpacity(0.1),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: c.computeLuminance() > 0.5
                        ? AppTheme.textPrimary
                        : Colors.white,
                  )
                : null,
          ),
        );
      },
    );
  }
}
