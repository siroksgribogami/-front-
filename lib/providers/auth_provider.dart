import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  /// Опрос показываем только после регистрации (после экрана приветствия), не при обычном входе.
  bool _pendingPostRegisterSurvey = false;
  bool _isInitialized = false;
  /// Тип помещения из опроса: apartment, house, office, commerce, hotel (для подписи «Моя квартира» и т.д.)
  String? _premiseType;
  /// Режим аккаунта: b2c | b2b | p2p | service
  String? _accountMode;
  /// Режим использования: family | personal | business
  String? _usageMode;

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  String? get premiseType => _premiseType;
  String? get accountMode => _accountMode;
  String? get usageMode => _usageMode;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get needsSurvey => isAuthenticated && _pendingPostRegisterSurvey;
  bool get justRegistered => _justRegistered;
  bool get isInitialized => _isInitialized;

  /// Инициализация - проверка токена при старте. При входе опрос не показываем.
  Future<void> initialize() async {
    _setState(AuthState.loading);
    _pendingPostRegisterSurvey = false;

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        try {
          _user = await _authService.getCurrentUser()
              .timeout(const Duration(seconds: 8));
          _justRegistered = false;
          _setState(AuthState.authenticated);
        } catch (_) {
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
      _loadPremiseType();
      notifyListeners();
    }
  }

  Future<void> _loadPremiseType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _premiseType = prefs.getString('arthouse_premise_type');
      _accountMode = prefs.getString('arthouse_account_mode');
      _usageMode = prefs.getString('arthouse_usage_mode');
    } catch (_) {}
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

    // Demo login для тестировщика (когда бэкенд недоступен или нужен быстрый вход по ролям)
    final demo = _resolveDemoAccount(email, password);
    if (demo != null) {
      _user = demo.user;
      _premiseType = demo.premiseType;
      _accountMode = demo.accountMode;
      _usageMode = demo.usageMode;
      await _saveAccountContext(
        premiseType: _premiseType,
        accountMode: _accountMode,
        usageMode: _usageMode,
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
    required String premiseType,
    required String accountMode,
    String? usageMode,
    required int totalArea,
    required int wallHeight,
    required int floorsCount,
    required int roomsCount,
  }) async {
    try {
      _premiseType = premiseType;
      _accountMode = accountMode;
      _usageMode = usageMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arthouse_premise_type', premiseType);
      await prefs.setString('arthouse_account_mode', accountMode);
      if (usageMode != null) {
        await prefs.setString('arthouse_usage_mode', usageMode);
      } else {
        await prefs.remove('arthouse_usage_mode');
      }

      _user = await _authService.updateProfile({
        'user_type': userType.name,
        'total_area': totalArea,
        'wall_height': wallHeight,
        'floors_count': floorsCount,
        'rooms_count': roomsCount,
        'survey_completed': true,
      });
      _justRegistered = false;
      _pendingPostRegisterSurvey = false;
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

  /// После экрана приветствия после регистрации — показываем опрос (только в этом потоке).
  void completePostRegisterWelcome() {
    if (!_justRegistered) return;
    _justRegistered = false;
    _pendingPostRegisterSurvey = true;
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

  Future<void> _saveAccountContext({
    String? premiseType,
    String? accountMode,
    String? usageMode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (premiseType != null) {
        await prefs.setString('arthouse_premise_type', premiseType);
      }
      if (accountMode != null) {
        await prefs.setString('arthouse_account_mode', accountMode);
      }
      if (usageMode != null) {
        await prefs.setString('arthouse_usage_mode', usageMode);
      } else {
        await prefs.remove('arthouse_usage_mode');
      }
    } catch (_) {}
  }

  _DemoAccount? _resolveDemoAccount(String email, String password) {
    final e = email.toLowerCase().trim();
    if (password != 'dev123*') return null;

    if (e == 'tester.b2c@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 101,
          email: e,
          username: 'Tester B2C',
          userType: UserType.b2c,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'apartment',
        accountMode: 'b2c',
        usageMode: 'family',
      );
    }

    if (e == 'tester.b2b@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 102,
          email: e,
          username: 'Tester B2B',
          userType: UserType.b2b,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'office',
        accountMode: 'b2b',
        usageMode: 'business',
      );
    }

    if (e == 'tester.p2p@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 103,
          email: e,
          username: 'Tester P2P',
          userType: UserType.b2c,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'apartment',
        accountMode: 'p2p',
        usageMode: 'personal',
      );
    }

    if (e == 'tester.service@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 104,
          email: e,
          username: 'Tester Service',
          userType: UserType.service,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'service_access',
        accountMode: 'service',
        usageMode: 'business',
      );
    }

    if (e == 'dev@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 1,
          email: e,
          username: 'DevAdmin',
          role: UserRole.admin,
          userType: UserType.b2b,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'commerce',
        accountMode: 'b2b',
        usageMode: 'business',
      );
    }
    return null;
  }
}

class _DemoAccount {
  final User user;
  final String accountMode;
  final String premiseType;
  final String? usageMode;

  const _DemoAccount({
    required this.user,
    required this.accountMode,
    required this.premiseType,
    this.usageMode,
  });
}
