import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_marketplace_role.dart';
import '../models/marketplace_project.dart';
import '../models/onboarding_survey.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/project_service.dart';
import '../services/survey_service.dart';
import '../services/marketplace_local_store.dart';
import '../data/premise_rooms_catalog.dart';
import '../utils/register_api_error_localizer.dart';
import '../utils/user_contact_display.dart';
import 'role_provider.dart';

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
  final SurveyService _surveyService = SurveyService();
  final ProjectService _projectService = ProjectService();
  
  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  bool _justRegistered = false;
  /// После регистрации показываем экран подтверждения email (UX; факт верификации — с сервера).
  bool _pendingEmailVerificationStep = false;
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

  /// Роль с экрана регистрации (`customer` | `master`) — для опроса без повторного вопроса.
  OnboardingRole? get registeredOnboardingRole {
    final mode = _accountMode;
    if (mode == 'master') return OnboardingRole.master;
    if (mode == 'customer') return OnboardingRole.customer;
    return null;
  }
  bool get justRegistered => _justRegistered;
  bool get needsEmailVerification =>
      isAuthenticated && _pendingEmailVerificationStep;
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
    String? phone,
    String? role,
  }) async {
    _setState(AuthState.loading);
    _error = null;

    try {
      final userData = UserCreate(
        email: email,
        username: username,
        password: password,
        userType: userType,
        phone: phone,
        role: role,
      );
      
      await _authService.register(userData);
      _user = await _authService.getCurrentUser();
      if (role == 'master' || role == 'customer') {
        _accountMode = role;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('arthouse_account_mode', role!);
        final isMaster = role == 'master';
        await prefs.setBool('arthouse_mp_role_customer', !isMaster);
        await prefs.setBool('arthouse_mp_role_master', isMaster);
        await prefs.setString(
          'arthouse_mp_active_role',
          isMaster ? 'master' : 'customer',
        );
        // Роль выбрана на регистрации и больше не меняется.
        // Тот же ключ, что и для демо-аккаунтов: `isMarketplaceRoleLocked == true`.
        await prefs.setString(
          RoleProvider.demoFixedMarketplaceRoleKey,
          isMaster ? 'master' : 'customer',
        );
      }
      _justRegistered = true;
      // При регистрации по телефону у нас фейковый @phone.arthouse.app — реального
      // ящика нет, экран подтверждения email только мешает. Показываем его
      // только для настоящих email-адресов.
      final isPhoneEmail =
          UserContactDisplay.isSyntheticPhoneEmail(email);
      _pendingEmailVerificationStep = !isPhoneEmail;
      _setState(AuthState.authenticated);
      return true;
    } on ApiException catch (e) {
      _setError(RegisterApiErrorLocalizer.localize(e));
      return false;
    } catch (e, st) {
      debugPrint('register error: $e\n$st');
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout')) {
        _setError(
          'Сервер не ответил вовремя.',
        );
      } else if (msg.contains('formatexception') || msg.contains('type ')) {
        _setError('Ошибка ответа сервера.');
      } else {
        _setError('Не удалось зарегистрироваться.');
      }
      return false;
    }
  }

  /// Закрыть шаг «подтвердите email» и перейти к приветствию / опросу.
  void completeEmailVerificationStep() {
    _pendingEmailVerificationStep = false;
    notifyListeners();
  }

  /// Запрос повторной отправки письма. Возвращает текст ошибки или `null` при успехе.
  ///
  /// **Бэкенд:** нужен `POST /api/v1/auth/resend-verification` с Bearer-токеном.
  Future<String?> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
      return null;
    } on ApiException catch (e) {
      return _mapResendVerificationError(e);
    } catch (_) {
      return 'Не удалось отправить письмо';
    }
  }

  /// Обновить профиль и вернуть `true`, если сервер сообщил `is_verified` (поле должно быть в ответе `/me`).
  Future<bool> refreshVerificationFromServer() async {
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
      return _user?.isVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  String _mapResendVerificationError(ApiException e) {
    if (e.statusCode == 404) {
      return 'На сервере пока нет отправки письма (эндпоинт не подключён). Это настраивается на бэкенде.';
    }
    if (e.statusCode == 429) {
      return 'Слишком частые запросы. Попробуйте через несколько минут.';
    }
    return RegisterApiErrorLocalizer.localize(e);
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
      await _syncDemoMarketplaceLockPref(demo.marketplaceLock);
      _justRegistered = false;
      _setState(AuthState.authenticated);
      return true;
    }

    try {
      final loginData = UserLogin(email: email, password: password);
      await _authService.login(loginData);
      _user = await _authService.getCurrentUser();
      _justRegistered = false;
      await _syncDemoMarketplaceLockPref(null);
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
    _pendingEmailVerificationStep = false;
    await _syncDemoMarketplaceLockPref(null);
    _setState(AuthState.unauthenticated);
  }

  /// Сохраняет поля, которых нет в ответе `PUT /me` (survey_completed и т.д.).
  User _mergeUserAfterProfileUpdate(User previous, User fromApi) {
    return fromApi.copyWith(
      surveyCompleted: previous.surveyCompleted,
      roomsCount: previous.roomsCount ?? fromApi.roomsCount,
      floorsCount: previous.floorsCount ?? fromApi.floorsCount,
      wallHeight: previous.wallHeight ?? fromApi.wallHeight,
      totalArea: previous.totalArea ?? fromApi.totalArea,
      isVerified: fromApi.isVerified || previous.isVerified,
    );
  }

  /// Обновить профиль
  Future<bool> updateProfile({String? username}) async {
    if (_user == null) return false;

    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      
      final previous = _user!;
      _user = _mergeUserAfterProfileUpdate(
        previous,
        await _authService.updateProfile(data),
      );
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

  /// Поменять отображаемое имя (`display_name` на бэкенде, не логин).
  ///
  /// UI обновляется сразу, серверный апдейт идёт в фоне; даже если API упадёт —
  /// локально имя остаётся изменённым (для офлайн / демо).
  Future<bool> setDisplayName(String value) async {
    final trimmed = value.trim();
    if (_user == null || trimmed.isEmpty) return false;
    if (trimmed == _user!.visibleName) return true;

    final previous = _user!;
    _user = previous.copyWith(displayName: trimmed);
    _error = null;
    notifyListeners();

    unawaited(() async {
      try {
        final fromApi = await _authService.updateProfile({'display_name': trimmed});
        final merged = _mergeUserAfterProfileUpdate(previous, fromApi).copyWith(
          displayName: fromApi.displayName ?? trimmed,
        );
        _user = merged;
        notifyListeners();
      } catch (_) {
        // Сервер недоступен — оставляем локальное имя.
      }
    }());
    return true;
  }

  /// Обновить номер телефона в профиле.
  Future<bool> setPhone(String value) async {
    final trimmed = value.trim();
    if (_user == null || trimmed.isEmpty) return false;

    final normalized = UserContactDisplay.normalizePhoneForApi(trimmed);
    if (normalized == _user!.phone) return true;

    final previous = _user!;
    _user = previous.copyWith(phone: normalized);
    _error = null;
    notifyListeners();

    unawaited(() async {
      try {
        final fromApi = await _authService.updateProfile({'phone': normalized});
        _user = _mergeUserAfterProfileUpdate(previous, fromApi).copyWith(
          phone: fromApi.phone ?? normalized,
        );
        notifyListeners();
      } catch (_) {}
    }());
    return true;
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

  /// Оценочная площадь (м²) для полей профиля/API из выбранного диапазона.
  static int _approxAreaSqm(String? areaId) {
    switch (areaId) {
      case 'area_xs':
        return 35;
      case 'area_s':
        return 55;
      case 'area_m':
        return 85;
      case 'area_l':
        return 120;
      default:
        return 55;
    }
  }

  /// Сохранить результаты пострегистрационного опроса (заказчик / мастер).
  Future<bool> submitSurvey({
    required OnboardingRole role,
    /// Заказчик: категории работ (мультивыбор)
    List<String>? workCategoryIds,
    /// Заказчик: первая/основная категория (legacy)
    String? workCategoryId,
    /// Заказчик: apartment | house | office
    String? premiseKind,
    /// Заказчик: количество этажей для дома
    String? houseFloors,
    /// Заказчик: точная площадь объекта, м²
    double? totalAreaSqm,
    /// Заказчик: условный диапазон площади (fallback)
    String? areaApproxId,
    /// Заказчик: выбранные комнаты с размерами
    List<Map<String, dynamic>>? roomsDetail,
    /// Заказчик: срок старта — urgent | within_month | browsing
    String? startTimelineId,
    /// Город (заказчик / мастер)
    String? city,
    /// Мастер: специализации (id)
    List<String>? specializationIds,
    /// Мастер: опыт — lt1 | y1_3 | y3_5 | gt5
    String? experienceId,
  }) async {
    if (_user == null) return false;
    _setState(AuthState.loading);
    notifyListeners();

    try {
      final isCustomer = role == OnboardingRole.customer;
      final userType = isCustomer ? UserType.b2c : UserType.service;

      final premiseType = isCustomer ? (premiseKind ?? 'apartment') : 'master';
      final categories = workCategoryIds ??
          (workCategoryId != null ? [workCategoryId] : <String>[]);
      final primaryWork = categories.isNotEmpty ? categories.first : workCategoryId;

      final totalArea = isCustomer
          ? (totalAreaSqm?.round() ??
              _approxAreaSqm(areaApproxId))
          : 50;
      const wallHeight = 260;
      const floorsCount = 1;
      final catalogRooms = isCustomer
          ? (roomsDetail != null && roomsDetail.isNotEmpty
              ? PremiseRoomsCatalog.roomsFromSurveySelections(roomsDetail)
              : PremiseRoomsCatalog.roomsForMap(premiseType))
          : <Map<String, dynamic>>[];
      final roomsCount =
          isCustomer ? catalogRooms.length.clamp(1, 99) : 1;

      final additional = <String, dynamic>{
        'onboarding_version': 3,
        'role': isCustomer ? 'customer' : 'master',
        if (isCustomer) ...{
          'work_categories': categories,
          'work_category': primaryWork,
          'total_area_sqm': totalArea,
          'start_timeline': startTimelineId,
          if (roomsDetail != null && roomsDetail.isNotEmpty)
            'rooms_detail': roomsDetail,
          if (houseFloors != null && premiseKind == 'house')
            'house_floors': houseFloors,
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        },
        if (!isCustomer) ...{
          'specializations': specializationIds ?? [],
          'experience': experienceId,
          'city': city?.trim(),
        },
      };

      try {
        await _surveyService.createSurvey({
          'property_type': premiseType,
          'total_area': totalArea.toDouble(),
          'total_area_unit': 'sqm',
          'ceiling_height': wallHeight / 100.0,
          'ceiling_height_unit': 'm',
          'floors_count': floorsCount,
          'rooms_count': roomsCount,
          'additional_info': additional,
        });
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
      }

      ProjectSummary? createdProject;
      if (isCustomer) {
        final projectTitle = _buildProjectTitle(
          workCategoryId: primaryWork,
          premiseType: premiseType,
        );
        final projectPayload = <String, dynamic>{
          'title': projectTitle,
          'work_type': primaryWork,
          'property_type': premiseType,
          'total_area': totalArea.toDouble(),
          'ceiling_height': wallHeight / 100.0,
          'floors_count': floorsCount,
          'rooms_count': roomsCount,
          if (houseFloors != null && premiseType == 'house') 'house_floors': houseFloors,
          'additional_info': additional,
          'map_data': <String, dynamic>{
            'before': <String, dynamic>{},
            'after': <String, dynamic>{},
            'rooms': catalogRooms,
            'source': 'post_register_survey',
          },
          'teaser': 'Черновик создан после опроса',
          'full_spec': _buildProjectFullSpec(
            premiseType: premiseType,
            totalArea: totalArea.toDouble(),
            houseFloors: houseFloors,
            workCategoryId: primaryWork,
            startTimelineId: startTimelineId,
          ),
        };
        try {
          createdProject = await _projectService.createDraftFromSurvey(projectPayload);
        } on ApiException catch (e) {
          // Проект не обязателен для завершения онбординга
          if (e.statusCode != 404 && e.statusCode != 0) rethrow;
        }
      }

      final accountModeLabel = isCustomer ? 'customer' : 'master';

      _premiseType = premiseType;
      _accountMode = accountModeLabel;
      _usageMode = isCustomer ? startTimelineId : null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arthouse_premise_type', premiseType);
      await prefs.setString('arthouse_account_mode', accountModeLabel);
      if (isCustomer && startTimelineId != null) {
        await prefs.setString('arthouse_start_timeline', startTimelineId);
      } else {
        await prefs.remove('arthouse_start_timeline');
      }
      if (isCustomer && houseFloors != null && premiseKind == 'house') {
        await prefs.setString('arthouse_house_floors', houseFloors);
      } else {
        await prefs.remove('arthouse_house_floors');
      }
      if (!isCustomer && city != null && city.trim().isNotEmpty) {
        await prefs.setString('arthouse_city', city.trim());
      } else {
        await prefs.remove('arthouse_city');
      }
      if (isCustomer) {
        await prefs.remove('arthouse_usage_mode');
        await PremiseRoomsCatalog.persistRoomsJson(catalogRooms);
        if (city != null && city.trim().isNotEmpty) {
          await prefs.setString('arthouse_city', city.trim());
        }
      } else {
        await prefs.remove(PremiseRoomsCatalog.prefsKey);
      }

      final created = createdProject;
      if (created != null) {
        await MarketplaceLocalStore.instance.ensureLoaded();
        final currentProjects = List<ProjectSummary>.from(
          MarketplaceLocalStore.instance.customerProjects,
        );
        final existingIndex = currentProjects.indexWhere((p) => p.id == created.id);
        if (existingIndex == -1) {
          currentProjects.insert(0, created);
        } else {
          currentProjects[existingIndex] = created;
        }
        await MarketplaceLocalStore.instance.saveCustomerProjects(currentProjects);
      }

      _user = _user!.copyWith(
        userType: userType,
        surveyCompleted: true,
        roomsCount: roomsCount,
        floorsCount: floorsCount,
        wallHeight: wallHeight,
        totalArea: totalArea,
      );
      _justRegistered = false;
      _pendingPostRegisterSurvey = false;
      _setState(AuthState.authenticated);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setState(AuthState.authenticated);
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Ошибка при сохранении опроса');
      _setState(AuthState.authenticated);
      notifyListeners();
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

  String _buildProjectTitle({
    required String? workCategoryId,
    required String premiseType,
  }) {
    final workLabel = _projectWorkCategoryLabel(workCategoryId) ?? 'Новый проект';
    final premiseLabel = switch (premiseType) {
      'house' => 'Дом',
      'office' => 'Офис',
      _ => 'Квартира',
    };
    return '$workLabel · $premiseLabel';
  }

  String _buildProjectFullSpec({
    required String premiseType,
    required double totalArea,
    required String? houseFloors,
    required String? workCategoryId,
    required String? startTimelineId,
  }) {
    final parts = <String>[
      'Тип: $premiseType',
      'Площадь: ${totalArea.toStringAsFixed(0)} м²',
      if (houseFloors != null && premiseType == 'house') 'Этажей: $houseFloors',
      if (workCategoryId != null) 'Категория: $workCategoryId',
      if (startTimelineId != null) 'Старт: $startTimelineId',
    ];
    return parts.join(' | ');
  }

  String? _projectWorkCategoryLabel(String? id) {
    switch (id) {
      case 'repair':
        return 'Ремонт';
      case 'design':
        return 'Дизайн';
      case 'cleaning':
        return 'Клининг';
      case 'furniture':
        return 'Сборка мебели';
      case 'electrical':
        return 'Электрика';
      case 'plumbing':
        return 'Сантехника';
      case 'other':
        return 'Другое';
      default:
        return null;
    }
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

  Future<void> _syncDemoMarketplaceLockPref(AppMarketplaceRole? lock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (lock != null) {
        await prefs.setString(RoleProvider.demoFixedMarketplaceRoleKey, lock.name);
      } else {
        await prefs.remove(RoleProvider.demoFixedMarketplaceRoleKey);
      }
    } catch (_) {}
  }

  _DemoAccount? _resolveDemoAccount(String email, String password) {
    final e = email.toLowerCase().trim();
    if (password != 'dev123*') return null;

    if (e == 'dev.customer@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 201,
          email: e,
          username: 'Dev заказчик',
          role: UserRole.user,
          userType: UserType.b2c,
          isActive: true,
          isVerified: true,
          surveyCompleted: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'apartment',
        accountMode: 'customer',
        usageMode: 'personal',
        marketplaceLock: AppMarketplaceRole.customer,
      );
    }

    if (e == 'dev.master@arthouse.ru') {
      return _DemoAccount(
        user: User(
          id: 202,
          email: e,
          username: 'Dev мастер',
          role: UserRole.user,
          userType: UserType.service,
          isActive: true,
          isVerified: true,
          surveyCompleted: true,
          createdAt: DateTime.now(),
        ),
        premiseType: 'master',
        accountMode: 'master',
        usageMode: 'business',
        marketplaceLock: AppMarketplaceRole.master,
      );
    }

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
        usageMode: 'personal',
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

    return null;
  }
}

class _DemoAccount {
  final User user;
  final String accountMode;
  final String premiseType;
  final String? usageMode;
  /// Если задано — вкладки маркетплейса только для этой роли (отдельные демо-аккаунты).
  final AppMarketplaceRole? marketplaceLock;

  const _DemoAccount({
    required this.user,
    required this.accountMode,
    required this.premiseType,
    this.usageMode,
    this.marketplaceLock,
  });
}
