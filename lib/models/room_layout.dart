import 'package:flutter/material.dart';

// ============================================================
//  МОДЕЛИ для 3D-редактора комнат (Sims-style)
// ============================================================

/// Категория мебели
enum FurnitureCategory {
  seating,   // Диваны, кресла
  tables,    // Столы
  storage,   // Шкафы, полки
  beds,      // Кровати
  appliances,// Техника
  decor,     // Декор, растения
  bathroom,  // Ванная
}

/// Описание типа мебели (шаблон из каталога)
class FurnitureTemplate {
  final String id;
  final String name;
  final String emoji;
  final FurnitureCategory category;
  final Color baseColor;
  final int tileWidth;   // ширина в клетках сетки
  final int tileHeight;  // высота в клетках сетки
  final String? glbAssetPath; // путь к 3D-модели .glb
  final List<Color> availableColors;

  const FurnitureTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.baseColor,
    this.tileWidth = 1,
    this.tileHeight = 1,
    this.glbAssetPath,
    this.availableColors = const [],
  });
}

/// Размещённый объект мебели на сетке
class PlacedFurniture {
  final String instanceId;
  final FurnitureTemplate template;
  int gridX;
  int gridY;
  int rotation; // 0 | 90 | 180 | 270 градусов
  Color color;

  PlacedFurniture({
    required this.instanceId,
    required this.template,
    required this.gridX,
    required this.gridY,
    this.rotation = 0,
    Color? color,
  }) : color = color ?? template.baseColor;

  PlacedFurniture copyWith({int? gridX, int? gridY, int? rotation, Color? color}) {
    return PlacedFurniture(
      instanceId: instanceId,
      template: template,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
    );
  }
}

/// Материал пола / обоев
class SurfaceMaterial {
  final String id;
  final String name;
  final Color color;
  final String? patternEmoji;

  const SurfaceMaterial({
    required this.id,
    required this.name,
    required this.color,
    this.patternEmoji,
  });
}

/// Планировка одной комнаты
class RoomLayout {
  final String id;
  String name;
  int gridWidth;
  int gridHeight;
  SurfaceMaterial floorMaterial;
  SurfaceMaterial wallMaterial;
  List<PlacedFurniture> furniture;

  RoomLayout({
    required this.id,
    required this.name,
    this.gridWidth = 8,
    this.gridHeight = 6,
    SurfaceMaterial? floorMaterial,
    SurfaceMaterial? wallMaterial,
    List<PlacedFurniture>? furniture,
  })  : floorMaterial = floorMaterial ?? kFloorMaterials.first,
        wallMaterial = wallMaterial ?? kWallMaterials.first,
        furniture = furniture ?? [];
}

// ============================================================
//  КАТАЛОГИ (данные)
// ============================================================

/// Встроенный каталог мебели
const List<FurnitureTemplate> kFurnitureCatalog = [
  // --- Диваны / Кресла ---
  FurnitureTemplate(
    id: 'sofa_2',
    name: 'Диван двухместный',
    emoji: '🛋️',
    category: FurnitureCategory.seating,
    baseColor: Color(0xFF8D9B8A),
    tileWidth: 3,
    tileHeight: 1,
    availableColors: [
      Color(0xFF8D9B8A), Color(0xFFB5896A), Color(0xFF5A6B7F), Color(0xFFE8DFCC),
    ],
  ),
  FurnitureTemplate(
    id: 'armchair',
    name: 'Кресло',
    emoji: '🪑',
    category: FurnitureCategory.seating,
    baseColor: Color(0xFFB5896A),
    tileWidth: 1,
    tileHeight: 1,
    availableColors: [
      Color(0xFFB5896A), Color(0xFF8D9B8A), Color(0xFF2A3A2C),
    ],
  ),
  // --- Столы ---
  FurnitureTemplate(
    id: 'dining_table',
    name: 'Обеденный стол',
    emoji: '🍽️',
    category: FurnitureCategory.tables,
    baseColor: Color(0xFFD4B896),
    tileWidth: 2,
    tileHeight: 2,
    availableColors: [
      Color(0xFFD4B896), Color(0xFF8B6B4A), Color(0xFF3A3A3A),
    ],
  ),
  FurnitureTemplate(
    id: 'coffee_table',
    name: 'Кофейный столик',
    emoji: '☕',
    category: FurnitureCategory.tables,
    baseColor: Color(0xFFD4B896),
    tileWidth: 2,
    tileHeight: 1,
  ),
  FurnitureTemplate(
    id: 'desk',
    name: 'Письменный стол',
    emoji: '🖥️',
    category: FurnitureCategory.tables,
    baseColor: Color(0xFFBCA882),
    tileWidth: 2,
    tileHeight: 1,
  ),
  // --- Кровати ---
  FurnitureTemplate(
    id: 'bed_double',
    name: 'Двуспальная кровать',
    emoji: '🛏️',
    category: FurnitureCategory.beds,
    baseColor: Color(0xFFE8DFCC),
    tileWidth: 2,
    tileHeight: 3,
    availableColors: [
      Color(0xFFE8DFCC), Color(0xFF8D9B8A), Color(0xFFB5896A),
    ],
  ),
  FurnitureTemplate(
    id: 'bed_single',
    name: 'Односпальная кровать',
    emoji: '🛌',
    category: FurnitureCategory.beds,
    baseColor: Color(0xFFE8DFCC),
    tileWidth: 1,
    tileHeight: 3,
  ),
  // --- Хранение ---
  FurnitureTemplate(
    id: 'wardrobe',
    name: 'Шкаф',
    emoji: '🚪',
    category: FurnitureCategory.storage,
    baseColor: Color(0xFFBCA882),
    tileWidth: 2,
    tileHeight: 1,
  ),
  FurnitureTemplate(
    id: 'bookshelf',
    name: 'Книжная полка',
    emoji: '📚',
    category: FurnitureCategory.storage,
    baseColor: Color(0xFF8B6B4A),
    tileWidth: 2,
    tileHeight: 1,
  ),
  // --- Техника ---
  FurnitureTemplate(
    id: 'tv',
    name: 'Телевизор',
    emoji: '📺',
    category: FurnitureCategory.appliances,
    baseColor: Color(0xFF3A3A3A),
    tileWidth: 2,
    tileHeight: 1,
  ),
  FurnitureTemplate(
    id: 'fridge',
    name: 'Холодильник',
    emoji: '🧊',
    category: FurnitureCategory.appliances,
    baseColor: Color(0xFFEEEEEE),
    tileWidth: 1,
    tileHeight: 1,
  ),
  FurnitureTemplate(
    id: 'washing_machine',
    name: 'Стиральная машина',
    emoji: '🫧',
    category: FurnitureCategory.appliances,
    baseColor: Color(0xFFEEEEEE),
    tileWidth: 1,
    tileHeight: 1,
  ),
  // --- Декор ---
  FurnitureTemplate(
    id: 'plant_big',
    name: 'Большое растение',
    emoji: '🌿',
    category: FurnitureCategory.decor,
    baseColor: Color(0xFF659171),
    tileWidth: 1,
    tileHeight: 1,
  ),
  FurnitureTemplate(
    id: 'rug',
    name: 'Ковёр',
    emoji: '🟫',
    category: FurnitureCategory.decor,
    baseColor: Color(0xFFD4956A),
    tileWidth: 3,
    tileHeight: 2,
    availableColors: [
      Color(0xFFD4956A), Color(0xFF8D9B8A), Color(0xFF5A6B7F), Color(0xFFE8DFCC),
    ],
  ),
  // --- Ванная ---
  FurnitureTemplate(
    id: 'bathtub',
    name: 'Ванная',
    emoji: '🛁',
    category: FurnitureCategory.bathroom,
    baseColor: Color(0xFFEEF4F2),
    tileWidth: 1,
    tileHeight: 3,
  ),
  FurnitureTemplate(
    id: 'toilet',
    name: 'Унитаз',
    emoji: '🚽',
    category: FurnitureCategory.bathroom,
    baseColor: Color(0xFFEEF4F2),
    tileWidth: 1,
    tileHeight: 1,
  ),
];

/// Каталог материалов пола
const List<SurfaceMaterial> kFloorMaterials = [
  SurfaceMaterial(id: 'parquet_light', name: 'Светлый паркет', color: Color(0xFFE8D5B0)),
  SurfaceMaterial(id: 'parquet_dark',  name: 'Тёмный паркет',  color: Color(0xFF8B6B4A)),
  SurfaceMaterial(id: 'tile_white',    name: 'Белая плитка',   color: Color(0xFFF0EDE8)),
  SurfaceMaterial(id: 'tile_grey',     name: 'Серая плитка',   color: Color(0xFFB0ADA8)),
  SurfaceMaterial(id: 'carpet_beige',  name: 'Бежевый ковёр',  color: Color(0xFFD8CCBC)),
  SurfaceMaterial(id: 'carpet_green',  name: 'Зелёный ковёр',  color: Color(0xFF80B490)),
  SurfaceMaterial(id: 'concrete',      name: 'Бетон',          color: Color(0xFFB8B5B0)),
];

/// Каталог обоев / цветов стен
const List<SurfaceMaterial> kWallMaterials = [
  SurfaceMaterial(id: 'wall_cream',    name: 'Кремовые',        color: Color(0xFFF7F3EC)),
  SurfaceMaterial(id: 'wall_sage',     name: 'Шалфейные',       color: Color(0xFF80B490)),
  SurfaceMaterial(id: 'wall_terracotta',name:'Терракотовые',    color: Color(0xFFD4956A)),
  SurfaceMaterial(id: 'wall_white',    name: 'Белые',           color: Color(0xFFFFFFFF)),
  SurfaceMaterial(id: 'wall_graphite', name: 'Графит',          color: Color(0xFF4A4A4A)),
  SurfaceMaterial(id: 'wall_blush',    name: 'Пыльная роза',    color: Color(0xFFE8C4B4)),
  SurfaceMaterial(id: 'wall_sky',      name: 'Небесные',        color: Color(0xFFB8D4E8)),
];
