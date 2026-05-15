import '../models/marketplace_project.dart';

/// Стартовый каталог маркетплейса в приложении (до интеграции с сервером).
/// Данные копируются в [MarketplaceLocalStore] при первом запуске.
class MarketplaceSeedCatalog {
  MarketplaceSeedCatalog._();

  static final List<ProjectSummary> customerProjects = [
    ProjectSummary(
      id: 'p1',
      title: 'Косметика гостиной',
      status: 'Черновик',
      updatedAt: DateTime(2026, 3, 10),
    ),
    ProjectSummary(
      id: 'p2',
      title: 'Санузел под ключ',
      status: 'Опубликован',
      updatedAt: DateTime(2026, 4, 2),
      responsesCount: 3,
    ),
    ProjectSummary(
      id: 'p3',
      title: 'Электрика в коридоре',
      status: 'В работе',
      updatedAt: DateTime(2026, 1, 18),
    ),
  ];

  /// Второй заказ с id `p2` совпадает с проектом p2 — отклики привязаны к одному id.
  static final List<OrderFeedItem> orderFeed = [
    const OrderFeedItem(
      id: 'o1',
      workType: 'Малярные работы',
      budgetLabel: '80 000 – 120 000 ₽',
      district: 'Москва, САО',
      addressShort: 'р-н Сокол, ~15 мин от метро',
      teaser: 'Покраска стен и потолка, подготовка под обои в одной комнате.',
      has3d: true,
      fullSpec:
          'Объект: гостиная 18 м². Шпаклёвка мелкозернистая, грунт, покраска потолка белым, стены под тон. Срок желательно до конца месяца.',
    ),
    const OrderFeedItem(
      id: 'p2',
      workType: 'Сантехника',
      budgetLabel: 'от 45 000 ₽',
      district: 'Москва, ЗАО',
      addressShort: 'Кунцево',
      teaser: 'Замена стояков, установка инсталляции, смесители.',
      has3d: false,
      fullSpec:
          'Санузел совмещённый 4 м². Демонтаж старой сантехники. Замена труб на ПП, инсталляция Geberit, подключение стиральной машины.',
    ),
  ];

  static List<MasterBid> bidsForProject(String projectId) {
    if (projectId != 'p2') return [];
    return const [
      MasterBid(
        id: 'b1',
        masterId: 'm1',
        masterName: 'Алексей М.',
        specialty: 'Электрика, мелкий ремонт',
        rating: 4.9,
        completedJobs: 38,
        priceOffer: '95 000 ₽',
        durationOffer: '14 дней',
        message: 'Готов приехать на замер в пятницу',
      ),
      MasterBid(
        id: 'b2',
        masterId: 'm2',
        masterName: 'Бригада «Угол»',
        specialty: 'Сантехника, плитка',
        rating: 4.8,
        completedJobs: 120,
        priceOffer: '102 000 ₽',
        durationOffer: '10 дней',
        message: 'Профлист сметы могу выслать сегодня',
      ),
    ];
  }

  static MasterProfile profileById(String masterId) {
    switch (masterId) {
      case 'm2':
        return const MasterProfile(
          id: 'm2',
          name: 'Бригада «Угол»',
          specialty: 'Сантехника · плитка',
          about:
              'Комплексные санузлы под ключ. Работаем по договору, делаем аккуратную разводку и чистовую отделку.',
          rating: 4.8,
          reviewsCount: 120,
          completedJobs: 120,
          statusLabel: 'ООО',
          portfolioPlaceholders: ['a', 'b', 'c', 'd', 'e', 'f'],
          certificates: [
            'СРО на строительные работы',
            'Сертификат на монтаж инженерных систем',
          ],
          reviews: [
            MasterReview(
              author: 'Елена',
              rating: 5.0,
              text: 'Сделали санузел за 12 дней, смету не раздули.',
            ),
            MasterReview(
              author: 'Игорь',
              rating: 4.7,
              text: 'Качественно, аккуратно по швам плитки.',
            ),
          ],
        );
      default:
        return const MasterProfile(
          id: 'm1',
          name: 'Алексей М.',
          specialty: 'Электрика · слаботочка',
          about:
              'Частный мастер по электрике квартир и домов. Беру объекты под ключ: щит, линии, освещение, финишный монтаж.',
          rating: 4.9,
          reviewsCount: 56,
          completedJobs: 56,
          statusLabel: 'Самозанятый',
          portfolioPlaceholders: ['1', '2', '3', '4', '5', '6'],
          certificates: [
            'Допуск по электробезопасности III группы',
            'Сертификат монтажа систем умного дома',
          ],
          reviews: [
            MasterReview(
              author: 'Анна',
              rating: 5.0,
              text: 'Перекинул всю электрику в трёшке, всё подписано и понятно.',
            ),
            MasterReview(
              author: 'Павел',
              rating: 4.8,
              text: 'Сделал аккуратно, помог с подбором автоматов.',
            ),
          ],
        );
    }
  }

  static final List<DirectChatThread> directChats = [
    DirectChatThread(
      id: 'c1',
      peerName: 'Алексей М.',
      masterId: 'm1',
      lastMessagePreview: 'Могу в пятницу на замер',
      updatedAt: DateTime(2026, 4, 20, 14, 30),
      projectTitle: 'Санузел под ключ',
    ),
    DirectChatThread(
      id: 'c2',
      peerName: 'Ольга К.',
      masterId: 'm2',
      lastMessagePreview: 'Спасибо, чертёж посмотрела',
      updatedAt: DateTime(2026, 4, 19, 9, 12),
      projectTitle: 'Косметика гостиной',
    ),
  ];

  /// Исполнители в каталоге поиска (id совпадают с профилями выше).
  static const List<Map<String, Object>> masterSearchEntries = [
    {
      'id': 'm1',
      'name': 'Алексей М.',
      'specialty': 'Электрика',
      'rating': 4.9,
      'jobs': 38,
    },
    {
      'id': 'm2',
      'name': 'Бригада «Угол»',
      'specialty': 'Плитка, сантехника',
      'rating': 4.8,
      'jobs': 120,
    },
  ];
}
