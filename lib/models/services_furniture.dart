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
  });
}

/// Локальный каталог услуг (данные хранятся в приложении до интеграции с сервером).
final List<ServiceCompany> catalogServices = [
  const ServiceCompany(
    id: 'service_1',
    name: 'Чистый Дом',
    category: 'Клининг',
    region: 'Москва',
    description: 'Профессиональная уборка квартир и домов. Генеральная уборка, после ремонта.',
    rating: 4.8,
    reviewsCount: 245,
    minPrice: 3500,
    priceRange: 'от 3 500 ₽',
    phone: '+7 (999) 123-45-67',
    icon: '🧹',
  ),
  const ServiceCompany(
    id: 'service_2',
    name: 'МастерОк',
    category: 'Ремонт',
    region: 'Московская область',
    description: 'Мелкий бытовой ремонт. Сборка мебели, установка техники, мелкие работы.',
    rating: 4.6,
    reviewsCount: 189,
    minPrice: 1500,
    priceRange: 'от 1 500 ₽',
    phone: '+7 (999) 234-56-78',
    icon: '🔨',
  ),
  const ServiceCompany(
    id: 'service_3',
    name: 'Сантех Сервис',
    category: 'Сантехника',
    region: 'Санкт-Петербург',
    description: 'Установка и ремонт сантехники. Устранение засоров, протечек.',
    rating: 4.7,
    reviewsCount: 312,
    minPrice: 2000,
    priceRange: 'от 2 000 ₽',
    phone: '+7 (999) 345-67-89',
    icon: '🔧',
  ),
  const ServiceCompany(
    id: 'service_4',
    name: 'ЭлектроМастер',
    category: 'Электрика',
    region: 'Москва',
    description: 'Электромонтажные работы. Замена проводки, установка розеток, люстр.',
    rating: 4.9,
    reviewsCount: 178,
    minPrice: 2500,
    priceRange: 'от 2 500 ₽',
    phone: '+7 (999) 456-78-90',
    icon: '⚡',
  ),
  const ServiceCompany(
    id: 'service_5',
    name: 'Переезд Легко',
    category: 'Перевозки',
    region: 'Казань',
    description: 'Квартирные и офисные переезды. Грузчики, упаковка, транспорт.',
    rating: 4.5,
    reviewsCount: 423,
    minPrice: 5000,
    priceRange: 'от 5 000 ₽',
    phone: '+7 (999) 567-89-01',
    icon: '📦',
  ),
];

/// Локальный каталог мебели.
final List<FurnitureItem> catalogFurniture = [
  const FurnitureItem(
    id: 'furn_1',
    name: 'Диван "Комфорт"',
    category: 'Гостиная',
    region: 'Москва',
    description: 'Раскладной диван с ящиком для белья. Механизм еврокнижка.',
    price: 45990,
    rating: 4.8,
    imageUrl: 'assets/images/sofa.jpg',
    dimensions: '210×95×85 см',
    material: 'Велюр, ДСП, пружинный блок',
    colors: ['Серый', 'Бежевый', 'Зелёный'],
  ),
  const FurnitureItem(
    id: 'furn_2',
    name: 'Стол обеденный "Скандинавия"',
    category: 'Кухня',
    region: 'Санкт-Петербург',
    description: 'Раздвижной стол из массива дуба. До 8 персон.',
    price: 32500,
    rating: 4.7,
    imageUrl: 'assets/images/table.jpg',
    dimensions: '140-180×90×76 см',
    material: 'Массив дуба, металл',
    colors: ['Натуральный дуб', 'Орех', 'Венге'],
  ),
  const FurnitureItem(
    id: 'furn_3',
    name: 'Кровать "Лофт"',
    category: 'Спальня',
    region: 'Москва',
    description: 'Двуспальная кровать с подъёмным механизмом и ящиком.',
    price: 38900,
    rating: 4.9,
    imageUrl: 'assets/images/bed.jpg',
    dimensions: '160×200 см (спальное место)',
    material: 'МДФ, ЛДСП, экокожа',
    colors: ['Белый', 'Графит', 'Бежевый'],
  ),
  const FurnitureItem(
    id: 'furn_4',
    name: 'Шкаф-купе "Модерн"',
    category: 'Спальня',
    region: 'Казань',
    description: 'Вместительный шкаф с зеркальными дверями. Внутреннее наполнение.',
    price: 54000,
    rating: 4.6,
    imageUrl: 'assets/images/wardrobe.jpg',
    dimensions: '240×60×220 см',
    material: 'ЛДСП, зеркало, алюминиевый профиль',
    colors: ['Белый', 'Дуб Сонома', 'Венге'],
  ),
  const FurnitureItem(
    id: 'furn_5',
    name: 'Стеллаж "Куб"',
    category: 'Гостиная',
    region: 'Московская область',
    description: 'Модульный стеллаж из 9 ячеек. Можно комбинировать.',
    price: 12990,
    rating: 4.5,
    imageUrl: 'assets/images/shelf.jpg',
    dimensions: '120×35×120 см',
    material: 'МДФ, металлические крепления',
    colors: ['Белый', 'Чёрный', 'Дуб'],
  ),
  const FurnitureItem(
    id: 'furn_6',
    name: 'Письменный стол "Офис"',
    category: 'Кабинет',
    region: 'Санкт-Петербург',
    description: 'Компактный стол для работы дома. Встроенный органайзер.',
    price: 15500,
    rating: 4.7,
    imageUrl: 'assets/images/desk.jpg',
    dimensions: '120×60×75 см',
    material: 'ЛДСП, металлический каркас',
    colors: ['Белый', 'Дуб', 'Графит'],
  ),
];
