import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Состояние аутентификации
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Провайдер аутентификации
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  bool _justRegistered = false;
  bool _isInitialized = false;

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get needsSurvey => isAuthenticated && !(_user?.surveyCompleted ?? false);
  bool get justRegistered => _justRegistered;
  bool get isInitialized => _isInitialized;

  /// Инициализация - проверка токена при старте
  Future<void> initialize() async {
    _setState(AuthState.loading);
    
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        try {
          _user = await _authService.getCurrentUser()
              .timeout(const Duration(seconds: 5));
          _justRegistered = false;
          _setState(AuthState.authenticated);
        } catch (_) {
          // Бэкенд недоступен или токен невалидный — показываем логин
          await _authService.logout();
          _justRegistered = false;
          _setState(AuthState.unauthenticated);
        }
      } else {
        _justRegistered = false;
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _justRegistered = false;
      _setState(AuthState.unauthenticated);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Регистрация
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    UserType userType = UserType.b2c,
  }) async {
    _setState(AuthState.loading);
    _error = null;

    try {
      final userData = UserCreate(
        email: email,
        username: username,
        password: password,
        userType: userType,
      );
      
      await _authService.register(userData);
      _user = await _authService.getCurrentUser();
      // Mark that the flow just registered — show survey even if backend state differs
      _justRegistered = true;
      _setState(AuthState.authenticated);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Ошибка при регистрации');
      return false;
    }
  }

  /// Вход
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
    _error = null;

    // Mock login для dev-учётки (когда бэкенд не запущен)
    if (email.toLowerCase() == 'dev@arthouse.ru' && password == 'dev123*') {
      _user = User(
        id: 1,
        email: 'dev@arthouse.ru',
        username: 'DevAdmin',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );
      _justRegistered = false;
      _setState(AuthState.authenticated);
      return true;
    }

    try {
      final loginData = UserLogin(email: email, password: password);
      await _authService.login(loginData);
      _user = await _authService.getCurrentUser();
      _justRegistered = false;
      _setState(AuthState.authenticated);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setState(AuthState.unauthenticated);
      return false;
    } catch (e) {
      _error = 'Ошибка при входе';
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  /// Выход
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _justRegistered = false;
    _setState(AuthState.unauthenticated);
  }

  /// Обновить профиль
  Future<bool> updateProfile({String? username}) async {
    if (_user == null) return false;

    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      
      _user = await _authService.updateProfile(data);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Ошибка при обновлении профиля');
      return false;
    }
  }

  /// Обновить тип пользователя (B2B/B2C)
  Future<bool> updateUserType(UserType userType) async {
    try {
      _user = await _authService.updateProfile({
        'user_type': userType.name,
      });
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Ошибка при обновлении типа пользователя');
      return false;
    }
  }

  /// Сохранить результаты опроса помещения
  Future<bool> submitSurvey({
    required UserType userType,
    required int totalArea,
    required int wallHeight,
    required int floorsCount,
    required int roomsCount,
  }) async {
    try {
      _user = await _authService.updateProfile({
        'user_type': userType.name,
        'total_area': totalArea,
        'wall_height': wallHeight,
        'floors_count': floorsCount,
        'rooms_count': roomsCount,
        'survey_completed': true,
      });
      // Clear justRegistered flag after finishing survey
      _justRegistered = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Ошибка при сохранении опроса');
      return false;
    }
  }

  /// Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Отметить, что приветственный экран после регистрации уже показан.
  void completePostRegisterWelcome() {
    if (!_justRegistered) return;
    _justRegistered = false;
    notifyListeners();
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _state = AuthState.error;
    notifyListeners();
  }
}
