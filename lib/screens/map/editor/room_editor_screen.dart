import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../providers/map_editor_provider.dart';
import 'furniture_catalog.dart';

// ─── Цвета из промта ───
const _sage = Color(0xFF659171);
const _terra = Color(0xFFD4956A);
const _cream = Color(0xFFF7F3EC);
const _dark = Color(0xFF2A3A2C);

/// Полноэкранный десктопный изометрический редактор комнаты.
/// Занимает всё пространство контента (показывается внутри HomeScreen).
///
/// Три зоны:
/// - Центральный канвас (кремовый фон) с Unity placeholder
/// - Правый тулбар (вертикальная пилюля #D4956A)
/// - Нижний sheet (планировка / мебель / задачи)
class RoomEditorScreen extends StatefulWidget {
  const RoomEditorScreen({
    super.key,
    this.initialRoomIndex = 0,
    this.onBack,
  });

  /// Индекс комнаты, которую показать при открытии.
  final int initialRoomIndex;

  /// Коллбэк «назад» — возвращает на обзор квартиры.
  final VoidCallback? onBack;

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen> with TickerProviderStateMixin {
  /// Индекс выбранной комнаты
  late int _activeRoomIndex;

  /// Текущий режим тулбара: 0 = планировка, 1 = мебель, 2 = задачи, null = закрыт
  int? _toolbarMode;

  /// Для планировки — какой чип активен (ПОЛ/СТЕНЫ/...)
  int _layoutChipIndex = 0;

  /// Для планировки — выбранная текстура
  int _activeTextureIndex = 0;

  /// Для мебели — выбранная категория (null = показать сетку категорий)
  int? _furnitureCategoryIndex;

  /// Выбранная мебель в комнате (имитация)
  String? _selectedFurniture;

  /// Показывать бейджи задач поверх 3D
  final bool _showTaskBadges = true;

  /// Текущая 3D-модель для просмотра (glb URL)
  String _activeModelUrl = 'models/Sofa.glb';

  /// Список размещённых предметов мебели (для отображения в списке)
  final List<FurnitureTemplate> _placedFurniture = [];

  /// Маппинг имени комнаты → GLB модель по умолчанию
  static const _roomDefaultModels = <String, String>{
    'Гостиная': 'models/Sofa.glb',
    'Спальня': 'models/Bed.glb',
    'Кухня': 'models/Fridge.glb',
    'Ванная': 'models/Wash_Machine.glb',
    'Кабинет': 'models/Desk.glb',
    'Детская': 'models/Chair.glb',
  };

  /// Top action bar показывается когда мебель выбрана
  bool get _showTopBar => _selectedFurniture != null;

  /// Controller для анимации bottom sheet
  late final AnimationController _sheetController;
  late final Animation<double> _sheetSlide;

  @override
  void initState() {
    super.initState();
    _activeRoomIndex = widget.initialRoomIndex;
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

  bool _modelInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modelInitialized) {
      _modelInitialized = true;
      final provider = context.read<MapEditorProvider>();
      final rooms = provider.rooms;
      if (_activeRoomIndex < rooms.length) {
        _activeModelUrl =
            _roomDefaultModels[rooms[_activeRoomIndex].name] ?? 'models/Sofa.glb';
      }
    }
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
        _furnitureCategoryIndex = null;
        _sheetController.forward();
      }
    });
  }

  void _closeSheet() {
    setState(() {
      _toolbarMode = null;
      _sheetController.reverse();
    });
  }

  void _selectFurniture(String? name) {
    setState(() => _selectedFurniture = name);
  }

  void _deleteFurniture() {
    setState(() {
      if (_selectedFurniture != null) {
        _placedFurniture.removeWhere((f) => f.name == _selectedFurniture);
      }
      _selectedFurniture = null;
      // Покажем последний размещённый предмет или вернём дефолт комнаты
      if (_placedFurniture.isNotEmpty) {
        final last = _placedFurniture.last;
        _activeModelUrl = last.modelUrl ?? _getDefaultModelForCurrentRoom();
      } else {
        _activeModelUrl = _getDefaultModelForCurrentRoom();
      }
    });
  }

  String _getDefaultModelForCurrentRoom() {
    final provider = context.read<MapEditorProvider>();
    final rooms = provider.rooms;
    if (_activeRoomIndex < rooms.length) {
      return _roomDefaultModels[rooms[_activeRoomIndex].name] ?? 'models/Sofa.glb';
    }
    return 'models/Sofa.glb';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapEditorProvider>();
    final rooms = provider.rooms;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E2D8),
      body: Column(
        children: [
          // Заголовок + табы комнат
          _buildHeader(rooms),
          // ГЛАВНОЕ: канвас с overlay
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // СЛОЙ 0 — ФОНОВЫЙ ЦВЕТ канваса
                    Container(color: _cream),

                    // СЛОЙ 1 — 3D модель (занимает весь канвас)
                    Positioned.fill(
                      child: _build3DViewer(),
                    ),

                    // СЛОЙ 2 — БЕЙДЖИ ЗАДАЧ поверх 3D
                    if (_showTaskBadges) ..._buildTaskBadges(),

                    // СЛОЙ 3 — Размещённая мебель (overlay внизу слева)
                    if (_placedFurniture.isNotEmpty)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: _buildPlacedFurnitureChips(),
                      ),

                    // СЛОЙ 4 — ВЕРХНЯЯ ПАНЕЛЬ ДЕЙСТВИЙ
                    if (_showTopBar)
                      Positioned(
                        top: 16,
                        left: 0, right: 0,
                        child: Center(child: _buildEditActionsBar()),
                      ),

                    // СЛОЙ 5 — ПРАВЫЙ ТУЛБАР (терракотовая пилюля)
                    Positioned(
                      right: 16,
                      top: 0, bottom: 0,
                      child: Center(child: _buildRightToolbar()),
                    ),

                    // СЛОЙ 6 — Bottom Sheet (выплывает снизу)
                    _buildBottomSheet(provider),

                    // СЛОЙ 7 — Подсказка управления
                    Positioned(
                      left: 0, right: 0,
                      bottom: 8,
                      child: Center(
                        child: Text(
                          'ЛКМ вращение · Колесо масштаб · СКМ перемещение',
                          style: TextStyle(
                            fontSize: 11,
                            color: _dark.withOpacity(0.35),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //   HEADER: Заголовок + Таб-переключатель комнат
  // ═══════════════════════════════════════════════

  Widget _buildHeader(List<MapEditorRoom> rooms) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onBack != null) ...[
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD8D4CC)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 20, color: _dark),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                'МОЙ ДОМ <3',
                style: AppTextStyle.gropled(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Pill tabs
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final isActive = index == _activeRoomIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeRoomIndex = index;
                      // Переключаем 3D на модель по умолчанию для этой комнаты
                      _activeModelUrl = _roomDefaultModels[room.name] ?? 'models/Sofa.glb';
                      _selectedFurniture = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? _terra : const Color(0xFFF0EDE4),
                      borderRadius: BorderRadius.circular(100),
                      border: isActive ? null : Border.all(color: const Color(0xFFD8D4CC)),
                    ),
                    child: Center(
                      child: Text(
                        room.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTextStyle.fontFamily,
                          height: AppTextStyle.defaultHeight,
                          color: isActive ? Colors.white : _dark,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //   3D VIEWER (model_viewer_plus)
  // ═══════════════════════════════════════════════

  Widget _build3DViewer() {
    return ModelViewer(
      key: ValueKey(_activeModelUrl),
      src: _activeModelUrl,
      alt: '3D просмотр',
      autoRotate: true,
      autoRotateDelay: 500,
      cameraControls: true,
      backgroundColor: _cream,
      shadowIntensity: 1,
      shadowSoftness: 0.8,
      exposure: 1.0,
      cameraOrbit: '45deg 55deg 2.5m',
    );
  }

  // ═══════════════════════════════════════════════
  //   TASK BADGES — плавающие поверх 3D
  // ═══════════════════════════════════════════════

  List<Widget> _buildTaskBadges() {
    final provider = context.read<MapEditorProvider>();
    final rooms = provider.rooms;
    if (_activeRoomIndex >= rooms.length) return [];
    final room = rooms[_activeRoomIndex];
    final tasks = room.taskList;
    if (tasks.isEmpty) return [];

    // Распределяем задачи по канвасу
    final positions = <(double, double)>[
      (0.15, 0.25),
      (0.55, 0.18),
      (0.35, 0.55),
      (0.65, 0.45),
      (0.20, 0.70),
    ];

    return List.generate(tasks.length.clamp(0, positions.length), (i) {
      final (left, top) = positions[i];
      return Positioned(
        left: left * (MediaQuery.of(context).size.width - 280),
        top: top * (MediaQuery.of(context).size.height - 200),
        child: GestureDetector(
          onTap: () => _openSheet(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _terra,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _terra.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white60,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tasks[i].length > 20 ? '${tasks[i].substring(0, 20)}…' : tasks[i],
                  style: const TextStyle(
                    fontFamily: AppTextStyle.fontFamily,
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Чипы размещённой мебели (можно нажать чтобы показать 3D)
  Widget _buildPlacedFurnitureChips() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _placedFurniture.map((item) {
          final isActive = _activeModelUrl == item.modelUrl;
          return GestureDetector(
            onTap: () {
              if (item.modelUrl != null) {
                setState(() {
                  _activeModelUrl = item.modelUrl!;
                  _selectedFurniture = item.name;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? _sage.withOpacity(0.9)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? _sage : _sage.withOpacity(0.2),
                ),
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
                  Text(item.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : _dark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //   RIGHT TOOLBAR: Вертикальная пилюля
  // ═══════════════════════════════════════════════

  Widget _buildRightToolbar() {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _terra,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: _terra.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: Icons.grid_view_rounded,
            tooltip: 'Редактировать планировку',
            active: _toolbarMode == 0,
            onTap: () => _openSheet(0),
          ),
          const SizedBox(height: 8),
          _ToolbarButton(
            icon: Icons.weekend_rounded,
            tooltip: 'Мебель / Обстановка',
            active: _toolbarMode == 1,
            onTap: () => _openSheet(1),
          ),
          const SizedBox(height: 8),
          _ToolbarButton(
            icon: Icons.check_circle_outline_rounded,
            tooltip: 'Задачи по предметам',
            active: _toolbarMode == 2,
            onTap: () => _openSheet(2),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //   BOTTOM SHEET — выплывает снизу
  // ═══════════════════════════════════════════════

  Widget _buildBottomSheet(MapEditorProvider provider) {
    return AnimatedBuilder(
      animation: _sheetSlide,
      builder: (context, child) {
        if (_sheetSlide.value == 0 && _toolbarMode == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: 0,
          right: 70,
          bottom: 0,
          height: 280 * _sheetSlide.value,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1EA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
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
                  // Drag handle
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
                  // Контент
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

  // ─── Режим «Планировка» ───

  static const _layoutChips = ['ПОЛ', 'СТЕНЫ', 'ОКНА', 'ДВЕРИ', 'АРКИ', 'ЛЕСТНИЦЫ'];

  static const _floorMaterials = [
    ('Паркет', Icons.square_rounded),
    ('Линолеум', Icons.square_rounded),
    ('Камень', Icons.square_rounded),
    ('Дерево', Icons.square_rounded),
    ('Ковралин', Icons.square_rounded),
    ('Бетон', Icons.square_rounded),
    ('Плитка', Icons.square_rounded),
  ];

  Widget _buildLayoutSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip row
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _terra : const Color(0xFFEEF1EE),
                    borderRadius: BorderRadius.circular(20),
                    border: isActive ? null : Border.all(color: const Color(0xFFD0D8D0)),
                  ),
                  child: Center(
                    child: Text(
                      _layoutChips[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
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
        // Material grid
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
                            color: Colors.white.withOpacity(isActive ? 0.6 : 0.4),
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

  // ─── Режим «Мебель» ───

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
              border: Border.all(
                color: const Color(0xFFD8D4CC),
                width: 1.5,
              ),
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
        // Кнопка назад + название категории
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
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: _dark),
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
                    // Превью 3D (если есть модель)
                    if (item.glbFile != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeModelUrl = item.modelUrl!;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _cream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _sage.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.view_in_ar_rounded, color: _sage, size: 18),
                        ),
                      ),
                    // + Добавить
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _placedFurniture.add(item);
                          if (item.modelUrl != null) {
                            _activeModelUrl = item.modelUrl!;
                          }
                          _selectedFurniture = item.name;
                        });
                        _closeSheet();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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

  // ─── Режим «Задачи» ───

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
              Text(
                'Задачи — ${room.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text(
                    'Задач пока нет',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isUrgent = index == 0; // первая задача — "срочная" для демо
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          const Icon(
                            Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: _sage,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _dark,
                              ),
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
        // FAB "Добавить задачу"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // TODO: диалог добавления задачи
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить задачу'),
              style: TextButton.styleFrom(
                foregroundColor: _sage,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //   EDIT ACTIONS BAR (поверх 3D)
  // ═══════════════════════════════════════════════

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
          // Отменить
          _actionBtn(
            icon: Icons.undo_rounded,
            color: const Color(0xFF7A8A7C),
            onTap: () {},
          ),
          // Повторить
          _actionBtn(
            icon: Icons.redo_rounded,
            color: const Color(0xFF7A8A7C),
            onTap: () {},
          ),
          Container(width: 1, height: 24, color: const Color(0xFFD8D4CC), margin: const EdgeInsets.symmetric(horizontal: 4)),
          // Удалить
          _actionBtn(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFC06060),
            onTap: _deleteFurniture,
          ),
          Container(width: 1, height: 24, color: const Color(0xFFD8D4CC), margin: const EdgeInsets.symmetric(horizontal: 4)),
          // Готово
          GestureDetector(
            onTap: () => _selectFurniture(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _sage,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Готово',
                style: TextStyle(
                  fontFamily: AppTextStyle.fontFamily,
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

  Widget _actionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//   Вспомогательные виджеты
// ═══════════════════════════════════════════════

/// Кнопка правого тулбара (белая иконка на терракоте)
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
