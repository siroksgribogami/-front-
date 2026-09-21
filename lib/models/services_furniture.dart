/// Модели каталога услуг и мебели (локально до подключения API).
/// Модель услуги (клининг, ремонт и т.д.)
class ServiceCompany {
  final String id;
  final String name;
  final String category;
  final String region;
  final String description;
  final double rating;
  final int reviewsCount;
  final int minPrice;
  final String priceRange;
  final String phone;
  final String icon;

  const ServiceCompany({
    required this.id,
    required this.name,
    required this.category,
    required this.region,
    required this.description,
    required this.rating,
    required this.reviewsCount,
    required this.minPrice,
    required this.priceRange,
    required this.phone,
    required this.icon,
  });
}

/// Модель мебели
class FurnitureItem {
  final String id;
  final String name;
  final String category;
  final String region;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;
  final String dimensions;
  final String material;
  final List<String> colors;
  final String manufacturer;
  final String? modelFile;

  const FurnitureItem({
    required this.id,
    required this.name,
    required this.category,
    required this.region,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.dimensions,
    required this.material,
    required this.colors,
    this.manufacturer = '',
    this.modelFile,
  });
}

/// Локальный каталог томских производителей до интеграции с сервером.
final List<ServiceCompany> catalogServices = [
  const ServiceCompany(
    id: 'service_1',
    name: 'Сибирская мастерская',
    category: 'Мебель на заказ',
    region: 'Томск',
    description: 'Мебель из массива и фанеры от локального производства в Томске.',
    rating: 4.8,
    reviewsCount: 245,
    minPrice: 3500,
    priceRange: 'от 3 500 ₽',
    phone: '+7 (3822) 12-34-56',
    icon: '🪵',
  ),
  const ServiceCompany(
    id: 'service_2',
    name: 'Томский текстиль',
    category: 'Текстиль для дома',
    region: 'Томск',
    description: 'Шторы, покрывала и мягкие детали интерьера с пошивом в Томске.',
    rating: 4.6,
    reviewsCount: 189,
    minPrice: 1500,
    priceRange: 'от 1 500 ₽',
    phone: '+7 (3822) 23-45-67',
    icon: '🧵',
  ),
  const ServiceCompany(
    id: 'service_3',
    name: 'Северный свет',
    category: 'Освещение',
    region: 'Томск',
    description: 'Светильники ручной сборки для жилых и общественных пространств.',
    rating: 4.7,
    reviewsCount: 312,
    minPrice: 2000,
    priceRange: 'от 2 000 ₽',
    phone: '+7 (3822) 34-56-78',
    icon: '💡',
  ),
  const ServiceCompany(
    id: 'service_4',
    name: 'Береста',
    category: 'Декор и посуда',
    region: 'Томск',
    description: 'Предметы декора и посуда из натуральных материалов Сибири.',
    rating: 4.9,
    reviewsCount: 178,
    minPrice: 2500,
    priceRange: 'от 2 500 ₽',
    phone: '+7 (3822) 45-67-89',
    icon: '🏺',
  ),
  const ServiceCompany(
    id: 'service_5',
    name: 'Сибирский дом',
    category: 'Дом и интерьер',
    region: 'Томск',
    description: 'Коллекция предметов для дома от небольших сибирских брендов.',
    rating: 4.5,
    reviewsCount: 423,
    minPrice: 5000,
    priceRange: 'от 5 000 ₽',
    phone: '+7 (3822) 56-78-90',
    icon: '🏠',
  ),
];

/// Локальный каталог товаров томских производителей.
final List<FurnitureItem> catalogFurniture = [
  const FurnitureItem(
    id: 'furn_1',
    name: 'Диван «Таёжный»',
    category: 'Гостиная',
    region: 'Томск',
    description: 'Диван локального производства с прочной обивкой и ящиком для белья.',
    price: 45990,
    rating: 4.8,
    imageUrl: 'assets/images/sofa.jpg',
    dimensions: '210×95×85 см',
    material: 'Велюр, ДСП, пружинный блок',
    colors: ['Серый', 'Бежевый', 'Зелёный'],
    manufacturer: 'Сибирская мастерская',
    modelFile: 'Sofa.glb',
  ),
  const FurnitureItem(
    id: 'furn_2',
    name: 'Стол «Кедр»',
    category: 'Кухня',
    region: 'Томск',
    description: 'Обеденный стол из сибирского кедра для большой семьи.',
    price: 32500,
    rating: 4.7,
    imageUrl: 'assets/images/table.jpg',
    dimensions: '140-180×90×76 см',
    material: 'Массив кедра, металл',
    colors: ['Натуральный кедр', 'Орех', 'Венге'],
    manufacturer: 'Сибирская мастерская',
    modelFile: 'Wood_Table.glb',
  ),
  const FurnitureItem(
    id: 'furn_3',
    name: 'Кровать «Север»',
    category: 'Спальня',
    region: 'Томск',
    description: 'Двуспальная кровать с мягким изголовьем и подъёмным механизмом.',
    price: 38900,
    rating: 4.9,
    imageUrl: 'assets/images/bed.jpg',
    dimensions: '160×200 см (спальное место)',
    material: 'МДФ, ЛДСП, экокожа',
    colors: ['Белый', 'Графит', 'Бежевый'],
    manufacturer: 'Сибирская мастерская',
    modelFile: 'Bed.glb',
  ),
  const FurnitureItem(
    id: 'furn_4',
    name: 'Шкаф «Тайга»',
    category: 'Спальня',
    region: 'Томск',
    description: 'Вместительный шкаф с натуральными фасадами и продуманным наполнением.',
    price: 54000,
    rating: 4.6,
    imageUrl: 'assets/images/wardrobe.jpg',
    dimensions: '240×60×220 см',
    material: 'ЛДСП, зеркало, алюминиевый профиль',
    colors: ['Белый', 'Сибирский кедр', 'Венге'],
    manufacturer: 'Сибирская мастерская',
    modelFile: 'Closet.glb',
  ),
  const FurnitureItem(
    id: 'furn_5',
    name: 'Стеллаж «Университетский»',
    category: 'Гостиная',
    region: 'Томск',
    description: 'Модульный стеллаж для книг, растений и коллекций.',
    price: 12990,
    rating: 4.5,
    imageUrl: 'assets/images/shelf.jpg',
    dimensions: '120×35×120 см',
    material: 'МДФ, металлические крепления',
    colors: ['Белый', 'Чёрный', 'Кедр'],
    manufacturer: 'Сибирская мастерская',
    modelFile: 'Metal_Shelving.glb',
  ),
  const FurnitureItem(
    id: 'furn_6',
    name: 'Рабочий стол «Лаборатория»',
    category: 'Кабинет',
    region: 'Томск',
    description: 'Компактный стол для дома с кабель-каналом и органайзером.',
    price: 15500,
    rating: 4.7,
    imageUrl: 'assets/images/desk.jpg',
    dimensions: '120×60×75 см',
    material: 'ЛДСП, металлический каркас',
    colors: ['Белый', 'Кедр', 'Графит'],
    manufacturer: 'Сибирская мастерская',
    modelFile: 'Desk.glb',
  ),
];
