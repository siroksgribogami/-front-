// Каталог мебели для редактора комнат АРТхаус.

class FurnitureTemplate {
  const FurnitureTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.widthCm,
    required this.depthCm,
    this.glbFile,
  });

  final String id;
  final String name;
  final String emoji;
  final String category;
  final int widthCm;
  final int depthCm;

  /// GLB файл из web/models/ (null = нет 3D-модели)
  final String? glbFile;

  String get dimensions => '$widthCm × $depthCm см';

  /// URL для model_viewer_plus (относительно web root)
  String? get modelUrl => glbFile != null ? 'models/$glbFile' : null;
}

/// Маппинг по умолчанию: id категории → файл .glb для превью
const defaultRoomModels = <String, String>{
  'living_room': 'Sofa.glb',
  'bedroom': 'Bed.glb',
  'kitchen': 'Fridge.glb',
  'bathroom': 'Wash_Machine.glb',
  'kids': 'Chair.glb',
  'storage': 'Metal_Shelving.glb',
  'tech': 'TV.glb',
  'decor': 'Wood_Table.glb',
};

class FurnitureCategory {
  const FurnitureCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.items,
  });

  final String id;
  final String name;
  final String emoji;
  final List<FurnitureTemplate> items;
}

const furnitureCatalog = <FurnitureCategory>[
  FurnitureCategory(
    id: 'living_room',
    name: 'Гостиная',
    emoji: '🛋️',
    items: [
      FurnitureTemplate(id: 'sofa_l', name: 'Диван угловой', emoji: '🛋️', category: 'living_room', widthCm: 260, depthCm: 160, glbFile: 'Sofa.glb'),
      FurnitureTemplate(id: 'sofa_s', name: 'Диван прямой', emoji: '🛋️', category: 'living_room', widthCm: 220, depthCm: 95, glbFile: 'Sofa.glb'),
      FurnitureTemplate(id: 'armchair', name: 'Кресло', emoji: '🪑', category: 'living_room', widthCm: 85, depthCm: 80, glbFile: 'Armchair.glb'),
      FurnitureTemplate(id: 'coffee_table', name: 'Журнальный столик', emoji: '🪟', category: 'living_room', widthCm: 120, depthCm: 60, glbFile: 'Wood_Table.glb'),
      FurnitureTemplate(id: 'bookshelf', name: 'Стеллаж', emoji: '📚', category: 'living_room', widthCm: 80, depthCm: 35, glbFile: 'Metal_Shelving.glb'),
      FurnitureTemplate(id: 'tv_stand', name: 'Тумба под ТВ', emoji: '📺', category: 'living_room', widthCm: 180, depthCm: 45, glbFile: 'TV.glb'),
    ],
  ),
  FurnitureCategory(
    id: 'bedroom',
    name: 'Спальня',
    emoji: '🛏️',
    items: [
      FurnitureTemplate(id: 'bed_double', name: 'Кровать двуспальная', emoji: '🛏️', category: 'bedroom', widthCm: 180, depthCm: 200, glbFile: 'Bed.glb'),
      FurnitureTemplate(id: 'bed_single', name: 'Кровать односпальная', emoji: '🛏️', category: 'bedroom', widthCm: 90, depthCm: 200, glbFile: 'Mattres.glb'),
      FurnitureTemplate(id: 'wardrobe', name: 'Шкаф-купе', emoji: '🚪', category: 'bedroom', widthCm: 200, depthCm: 60, glbFile: 'Closet.glb'),
      FurnitureTemplate(id: 'nightstand', name: 'Тумбочка', emoji: '🪟', category: 'bedroom', widthCm: 50, depthCm: 40, glbFile: 'Bedside_Dresser.glb'),
      FurnitureTemplate(id: 'dresser', name: 'Комод', emoji: '🗄️', category: 'bedroom', widthCm: 120, depthCm: 50, glbFile: 'Dresser.glb'),
    ],
  ),
  FurnitureCategory(
    id: 'kitchen',
    name: 'Кухня',
    emoji: '🍳',
    items: [
      FurnitureTemplate(id: 'fridge', name: 'Холодильник', emoji: '🧊', category: 'kitchen', widthCm: 60, depthCm: 65, glbFile: 'Fridge.glb'),
      FurnitureTemplate(id: 'stove', name: 'Плита', emoji: '🍳', category: 'kitchen', widthCm: 60, depthCm: 60, glbFile: 'Oven.glb'),
      FurnitureTemplate(id: 'kitchen_table', name: 'Обеденный стол', emoji: '🍽️', category: 'kitchen', widthCm: 140, depthCm: 80, glbFile: 'Wood_Table.glb'),
      FurnitureTemplate(id: 'kitchen_cabinet', name: 'Кухонный гарнитур', emoji: '🗄️', category: 'kitchen', widthCm: 240, depthCm: 60),
      FurnitureTemplate(id: 'dishwasher', name: 'Посудомоечная', emoji: '🫧', category: 'kitchen', widthCm: 60, depthCm: 60),
      FurnitureTemplate(id: 'microwave', name: 'Микроволновка', emoji: '📡', category: 'kitchen', widthCm: 50, depthCm: 40, glbFile: 'Micro_Wave.glb'),
    ],
  ),
  FurnitureCategory(
    id: 'bathroom',
    name: 'Ванная',
    emoji: '🛁',
    items: [
      FurnitureTemplate(id: 'bathtub', name: 'Ванна', emoji: '🛁', category: 'bathroom', widthCm: 170, depthCm: 70),
      FurnitureTemplate(id: 'shower', name: 'Душевая кабина', emoji: '🚿', category: 'bathroom', widthCm: 90, depthCm: 90),
      FurnitureTemplate(id: 'toilet', name: 'Унитаз', emoji: '🚽', category: 'bathroom', widthCm: 40, depthCm: 65),
      FurnitureTemplate(id: 'sink_bath', name: 'Раковина', emoji: '🚰', category: 'bathroom', widthCm: 60, depthCm: 45),
      FurnitureTemplate(id: 'wash_machine', name: 'Стиральная машина', emoji: '🧺', category: 'bathroom', widthCm: 60, depthCm: 55, glbFile: 'Wash_Machine.glb'),
    ],
  ),
  FurnitureCategory(
    id: 'kids',
    name: 'Детская',
    emoji: '🧒',
    items: [
      FurnitureTemplate(id: 'kids_bed', name: 'Детская кровать', emoji: '🛏️', category: 'kids', widthCm: 80, depthCm: 170, glbFile: 'Mattres.glb'),
      FurnitureTemplate(id: 'kids_desk', name: 'Рабочий стол', emoji: '📝', category: 'kids', widthCm: 120, depthCm: 60, glbFile: 'Desk.glb'),
      FurnitureTemplate(id: 'toy_chest', name: 'Ящик для игрушек', emoji: '🧸', category: 'kids', widthCm: 80, depthCm: 50),
      FurnitureTemplate(id: 'kids_wardrobe', name: 'Шкаф', emoji: '🚪', category: 'kids', widthCm: 120, depthCm: 55, glbFile: 'Closet.glb'),
    ],
  ),
  FurnitureCategory(
    id: 'storage',
    name: 'Кладовая',
    emoji: '📦',
    items: [
      FurnitureTemplate(id: 'shelf_unit', name: 'Стеллаж', emoji: '📦', category: 'storage', widthCm: 80, depthCm: 40, glbFile: 'Metal_Shelving.glb'),
      FurnitureTemplate(id: 'storage_cabinet', name: 'Шкаф хранения', emoji: '🗄️', category: 'storage', widthCm: 100, depthCm: 50, glbFile: 'Closet.glb'),
    ],
  ),
  FurnitureCategory(
    id: 'tech',
    name: 'Техника',
    emoji: '📺',
    items: [
      FurnitureTemplate(id: 'tv', name: 'Телевизор', emoji: '📺', category: 'tech', widthCm: 120, depthCm: 8, glbFile: 'TV.glb'),
      FurnitureTemplate(id: 'ac_unit', name: 'Кондиционер', emoji: '❄️', category: 'tech', widthCm: 80, depthCm: 25),
      FurnitureTemplate(id: 'speaker', name: 'Колонка', emoji: '🔊', category: 'tech', widthCm: 20, depthCm: 20),
    ],
  ),
  FurnitureCategory(
    id: 'decor',
    name: 'Декор',
    emoji: '🪴',
    items: [
      FurnitureTemplate(id: 'plant_big', name: 'Растение напольное', emoji: '🪴', category: 'decor', widthCm: 40, depthCm: 40),
      FurnitureTemplate(id: 'plant_small', name: 'Растение настольное', emoji: '🌱', category: 'decor', widthCm: 20, depthCm: 20),
      FurnitureTemplate(id: 'floor_lamp', name: 'Торшер', emoji: '💡', category: 'decor', widthCm: 35, depthCm: 35),
      FurnitureTemplate(id: 'table_lamp', name: 'Настольная лампа', emoji: '🔦', category: 'decor', widthCm: 25, depthCm: 25),
      FurnitureTemplate(id: 'rug', name: 'Ковёр', emoji: '🟫', category: 'decor', widthCm: 200, depthCm: 150),
      FurnitureTemplate(id: 'mirror', name: 'Зеркало', emoji: '🪞', category: 'decor', widthCm: 60, depthCm: 5),
    ],
  ),
];
