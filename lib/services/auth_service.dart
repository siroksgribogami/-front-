import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Сервис аутентификации
class AuthService {
  final ApiService _api = ApiService();

  /// Регистрация нового пользователя
  Future<AuthToken> register(UserCreate userData) async {
    final response = await _api.post(
      ApiConfig.authRegister,
      body: userData.toJson(),
    );
    
    final token = AuthToken.fromJson(response);
    await _api.saveToken(token.accessToken);
    return token;
  }

  /// Вход в систему
  Future<AuthToken> login(UserLogin loginData) async {
    final response = await _api.post(
      ApiConfig.authLogin,
      body: loginData.toJson(),
    );
    
    final token = AuthToken.fromJson(response);
    await _api.saveToken(token.accessToken);
    return token;
  }

  /// Получить текущего пользователя
  Future<User> getCurrentUser() async {
    final response = await _api.get(
      ApiConfig.usersMe,
      requireAuth: true,
    );
    return User.fromJson(response);
  }

  /// Обновить профиль пользователя
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put(
      ApiConfig.usersMe,
      body: data,
      requireAuth: true,
    );
    return User.fromJson(response);
  }

  /// Выход из системы
  Future<void> logout() async {
    await _api.deleteToken();
  }

  /// Повторная отправка письма с ссылкой подтверждения email.
  ///
  /// **Бэкенд (нужно реализовать):** `POST /api/v1/auth/resend-verification` с заголовком
  /// `Authorization: Bearer <access_token>`. Ответ `204 No Content` или JSON со статусом.
  /// На сервере: SMTP или почтовый API, одноразовый токен/запись в БД, срок действия ссылки,
  /// защита от спама (rate limit).
  Future<void> resendVerificationEmail() async {
    await _api.post(
      ApiConfig.authResendVerification,
      body: <String, dynamic>{},
      requireAuth: true,
    );
  }

  /// Проверить авторизацию
  Future<bool> isAuthenticated() async {
    return _api.isAuthenticated();
  }
}
