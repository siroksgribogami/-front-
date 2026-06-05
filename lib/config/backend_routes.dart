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
}
