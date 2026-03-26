/// Конфигурация API для подключения к бэкенду
class ApiConfig {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000';

  /// Базовый URL API. На Android-эмуляторе подставляется 10.0.2.2 (хост ПК).
  /// Переопределить: ApiConfig.baseUrlOverride = 'http://192.168.1.10:8000';
  static String? baseUrlOverride;

  static String get baseUrl => baseUrlOverride ?? _defaultBaseUrl;

  /// Версия API
  static const String apiVersion = '/api/v1';

  /// Полный базовый URL API
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  /// Endpoints аутентификации
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  
  /// Endpoints пользователей
  static const String usersMe = '/users/me';
  
  /// Endpoints квартир
  static const String apartmentsMy = '/apartments/my';
  static const String tasks = '/tasks';
  
  /// Таймаут для запросов
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Ключ для хранения токена
  static const String tokenKey = 'access_token';
}
