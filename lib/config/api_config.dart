/// Конфигурация API для подключения к бэкенду
class ApiConfig {
  /// Базовый URL API (измените для production)
  static const String baseUrl = 'http://127.0.0.1:8000';
  
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
  
  /// Таймаут для запросов
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Ключ для хранения токена
  static const String tokenKey = 'access_token';
}
