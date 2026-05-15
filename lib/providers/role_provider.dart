import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_marketplace_role.dart';

/// Роли маркетплейса: какие режимы включены и какой сейчас активен (влияет на табы и ЛК).
class RoleProvider extends ChangeNotifier {
  static const _keyCustomer = 'arthouse_mp_role_customer';
  static const _keyMaster = 'arthouse_mp_role_master';
  static const _keyActive = 'arthouse_mp_active_role';

  /// Если задано — роль привязана к аккаунту (демо заказчик / демо мастер), переключатель в профиле скрыт.
  static const String demoFixedMarketplaceRoleKey = 'arthouse_demo_fixed_mp_role';

  bool _customerEnabled = true;
  bool _masterEnabled = false;
  AppMarketplaceRole _activeRole = AppMarketplaceRole.customer;
  AppMarketplaceRole? _demoLockedRole;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get customerEnabled => _customerEnabled;
  bool get masterEnabled => _masterEnabled;
  AppMarketplaceRole get activeRole => _activeRole;
  AppMarketplaceRole? get demoLockedRole => _demoLockedRole;
  bool get isMarketplaceRoleLocked => _demoLockedRole != null;

  /// Переключение заказчик/мастер в ЛК (если аккаунт не зафиксирован демо-логином).
  bool get canSwitchRole => !isMarketplaceRoleLocked;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lockedName = prefs.getString(demoFixedMarketplaceRoleKey);
      if (lockedName == AppMarketplaceRole.customer.name) {
        _demoLockedRole = AppMarketplaceRole.customer;
        _customerEnabled = true;
        _masterEnabled = false;
        _activeRole = AppMarketplaceRole.customer;
        _loaded = true;
        notifyListeners();
        return;
      }
      if (lockedName == AppMarketplaceRole.master.name) {
        _demoLockedRole = AppMarketplaceRole.master;
        _customerEnabled = false;
        _masterEnabled = true;
        _activeRole = AppMarketplaceRole.master;
        _loaded = true;
        notifyListeners();
        return;
      }
      _demoLockedRole = null;

      _customerEnabled = prefs.getBool(_keyCustomer) ?? true;
      _masterEnabled = prefs.getBool(_keyMaster) ?? false;
      final activeName = prefs.getString(_keyActive);
      if (activeName == AppMarketplaceRole.master.name) {
        _activeRole = AppMarketplaceRole.master;
      } else {
        _activeRole = AppMarketplaceRole.customer;
      }
      _ensureConsistency();
    } catch (_) {
      _demoLockedRole = null;
      _customerEnabled = true;
      _masterEnabled = false;
      _activeRole = AppMarketplaceRole.customer;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  void _ensureConsistency() {
    if (_activeRole == AppMarketplaceRole.customer) {
      _customerEnabled = true;
      _masterEnabled = false;
      return;
    }
    _customerEnabled = false;
    _masterEnabled = true;
  }

  Future<void> setCustomerEnabled(bool value) async {
    if (isMarketplaceRoleLocked) return;
    _customerEnabled = value;
    if (value) {
      _masterEnabled = false;
      _activeRole = AppMarketplaceRole.customer;
    }
    _ensureConsistency();
    await _persist();
    notifyListeners();
  }

  Future<void> setMasterEnabled(bool value) async {
    if (isMarketplaceRoleLocked) return;
    _masterEnabled = value;
    if (value) {
      _customerEnabled = false;
      _activeRole = AppMarketplaceRole.master;
    }
    _ensureConsistency();
    await _persist();
    notifyListeners();
  }

  Future<void> setActiveRole(AppMarketplaceRole role) async {
    if (isMarketplaceRoleLocked) return;
    _activeRole = role;
    _ensureConsistency();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCustomer, _customerEnabled);
      await prefs.setBool(_keyMaster, _masterEnabled);
      await prefs.setString(_keyActive, _activeRole.name);
    } catch (_) {}
  }
}
