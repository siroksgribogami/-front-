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

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  /// Инициализация - проверка токена при старте
  Future<void> initialize() async {
    _setState(AuthState.loading);
    
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _user = await _authService.getCurrentUser();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } on ApiException catch (e) {
      // Если токен невалидный, выходим
      if (e.statusCode == 401) {
        await _authService.logout();
        _setState(AuthState.unauthenticated);
      } else {
        _setError(e.message);
      }
    } catch (e) {
      _setState(AuthState.unauthenticated);
    }
  }

  /// Регистрация
  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _setState(AuthState.loading);
    _error = null;

    try {
      final userData = UserCreate(
        email: email,
        username: username,
        password: password,
      );
      
      await _authService.register(userData);
      _user = await _authService.getCurrentUser();
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
    if (email == 'dev@arthouse.ru' && password == 'dev123*') {
      _user = User(
        id: 1,
        email: 'dev@arthouse.ru',
        username: 'DevAdmin',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );
      _setState(AuthState.authenticated);
      return true;
    }

    try {
      final loginData = UserLogin(email: email, password: password);
      await _authService.login(loginData);
      _user = await _authService.getCurrentUser();
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

  /// Очистить ошибку
  void clearError() {
    _error = null;
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
