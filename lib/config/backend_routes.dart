/// Пути REST API относительно [ApiConfig.apiBaseUrl] (`…/api/v1`).
/// Соответствуют роутерам в `art_back/app/api/v1/endpoints/` (префиксы в
/// api.py: auth → `/auth`, users → `/users`, …).
abstract final class BackendRoutes {
  BackendRoutes._();

  static const authRegister = '/register';
  static const authLogin = '/login';

  /// Повторная отправка письма подтверждения email (реализуется на бэкенде).
  static const authResendVerification = '/auth/resend-verification';

  static const usersMe = '/users/me';

  static const apartmentsMy = '/apartments/my';

  /// Опросы: в бэке см. `surveys` router.
  static const surveys = '/surveys';
  static const surveysDashboard = '/surveys/dashboard';
  static const surveysLatest = '/surveys/latest';

  /// Снимки 3D-плана квартиры.
  static const snapshots = '/snapshots';

  /// Задачи: в бэке см. `tasks` router.
  static const tasks = '/tasks';

  /// Комнаты: в бэке роуты без общего префикса (`/apartments/{id}/rooms`, `/rooms/{id}`).
  static const apartments = '/apartments';
  static const rooms = '/rooms';

  /// Корневой health вне версии API — `GET {baseUrl}/health` (см. `app/main.py`).
  static const health = '/health';
}
