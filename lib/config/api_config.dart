import 'backend_routes.dart';

/// Конфигурация API для подключения к бэкенду `art_back` (FastAPI, `/api/v1`).
class ApiConfig {
  static const String _defaultBaseUrl = 'http://localhost:8000';

  /// Базовый URL без `/api/v1`. На Android-эмуляторе задаётся в [api_config_platform_io].
  /// Сборка: `--dart-define=API_BASE_URL=http://192.168.0.5:8000`
  static String? baseUrlOverride;

  static String get baseUrl => baseUrlOverride ?? _defaultBaseUrl;

  /// Префикс версии (как `API_V1_STR` в бэке).
  static const String apiVersion = '/api/v1';

  /// База для всех методов API: `{baseUrl}/api/v1`
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Корневой URL для [BackendRoutes.health] (`GET /health` на том же хосте).
  static String get rootBaseUrl => baseUrl;

  static const String authRegister = BackendRoutes.authRegister;
  static const String authLogin = BackendRoutes.authLogin;
  static const String authResendVerification = BackendRoutes.authResendVerification;
  static const String usersMe = BackendRoutes.usersMe;
  static const String surveys = BackendRoutes.surveys;
  static const String surveysDashboard = BackendRoutes.surveysDashboard;
  static const String surveysLatest = BackendRoutes.surveysLatest;
  static const String snapshots = BackendRoutes.snapshots;
  static const String tasks = BackendRoutes.tasks;
  static const String apartmentsMy = BackendRoutes.apartmentsMy;
  static const String apartments = BackendRoutes.apartments;
  static const String rooms = BackendRoutes.rooms;

  static const Duration requestTimeout = Duration(seconds: 30);

  static const String tokenKey = 'access_token';
}
