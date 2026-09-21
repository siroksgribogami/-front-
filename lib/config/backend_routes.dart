/// Пути REST API относительно [ApiConfig.apiBaseUrl] (`…/api/v1`).
/// Соответствуют бэкенду Приделе (`ARThouse-backend`): роутеры в `app/api/v1/endpoints/` без
/// дополнительных префиксов (`/register`, `/me`, `/my`, `/dashboard`, …).
abstract final class BackendRoutes {
  BackendRoutes._();

  static const authRegister = '/register';
  static const authLogin = '/login';

  /// Повторная отправка письма подтверждения email (реализуется на бэкенде).
  static const authResendVerification = '/auth/resend-verification';

  static const usersMe = '/me';

  static const apartmentsMy = '/my';

  /// Опросы: эндпоинты на корне `/api/v1` (`surveys.py`).
  static const surveys = '/';
  static const surveysDashboard = '/dashboard';
  static const surveysLatest = '/latest';

  /// Снимки 3D-плана квартиры.
  static const snapshots = '/snapshots';

  /// Задачи: в бэке см. `tasks` router.
  static const tasks = '/tasks';

  /// Комнаты: в бэке роуты без общего префикса (`/apartments/{id}/rooms`, `/rooms/{id}`).
  static const apartments = '/apartments';
  static const rooms = '/rooms';

  /// Корневой health вне версии API — `GET {baseUrl}/health` (см. `app/main.py`).
  static const health = '/health';

  // --- Биржа (marketplace): реализовано на ARThouse-backend ---
  static const projects = '/projects';
  static const projectsMy = '/projects/my';
  static const orders = '/orders';
  static const ordersDistricts = '/orders/districts';

  /// Отклики: `/projects/{id}/bids`, `/bids/my`, `/projects/{id}/select-master`.
  static const bidsMy = '/bids/my';

  /// Чаты: `/chats/my`, `/chats`, `/chats/{threadId}/messages`.
  static const chatsMy = '/chats/my';
  static const chats = '/chats';

  /// ИИ-зрение (фото → мебель): `POST /ai-vision/detect-furniture`.
  static const aiVisionDetectFurniture = '/ai-vision/detect-furniture';
}
