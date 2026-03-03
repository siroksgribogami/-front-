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

  /// Проверить авторизацию
  Future<bool> isAuthenticated() async {
    return _api.isAuthenticated();
  }
}
