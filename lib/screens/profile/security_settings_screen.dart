import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../core/theme/brand_ui.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometric = false;
  bool _sessionLock = true;
  bool _loaded = false;

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometric = prefs.getBool('security_biometric') ?? false;
      _sessionLock = prefs.getBool('security_session_lock') ?? true;
      _loaded = true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _changePassword() {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполни все поля пароля')),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новый пароль должен быть не короче 6 символов')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подтверждение пароля не совпадает')),
      );
      return;
    }

    _oldCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пароль обновлён локально (демо-режим)')),
    );
  }

  Widget _settingsIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: BrandRuntime.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: BrandRuntime.needles),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const BrandScreen(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BrandScreen(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: BrandRuntime.canvas,
        foregroundColor: BrandRuntime.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: BrandAppBar(
            title: 'Безопасность',
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      padding: EdgeInsets.zero,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              BrandSettingsGroup(
                header: 'Вход в приложение',
                children: [
                  BrandSettingsRow(
                    icon: _settingsIcon(Icons.fingerprint_rounded),
                    label: 'Face ID / отпечаток',
                    trailing: BrandToggle(
                      value: _biometric,
                      onChanged: (v) {
                        setState(() => _biometric = v);
                        _saveBool('security_biometric', v);
                      },
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    icon: _settingsIcon(Icons.lock_outline_rounded),
                    label: 'Код-пароль',
                    value: 'Вкл',
                    onTap: () {},
                  ),
                  BrandSettingsRow(
                    icon: _settingsIcon(Icons.timer_outlined),
                    label: 'Блокировать через',
                    value: _sessionLock ? '1 мин' : 'Выкл',
                    trailing: BrandToggle(
                      value: _sessionLock,
                      onChanged: (v) {
                        setState(() => _sessionLock = v);
                        _saveBool('security_session_lock', v);
                      },
                    ),
                    showChevron: false,
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              BrandSettingsGroup(
                header: 'Пароль и сессии',
                children: [
                  BrandSettingsRow(
                    label: 'Сменить пароль',
                    onTap: () {},
                  ),
                  BrandSettingsRow(
                    label: 'Активные сессии',
                    value: '2 устройства',
                    onTap: () {},
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrandRuntime.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BrandRuntime.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Сменить пароль',
                      style: BrandUi.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrandRuntime.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _oldCtrl,
                      obscureText: true,
                      decoration: BrandUi.inputDecoration(hint: 'Текущий пароль'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newCtrl,
                      obscureText: true,
                      decoration: BrandUi.inputDecoration(hint: 'Новый пароль'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      decoration: BrandUi.inputDecoration(hint: 'Подтверждение'),
                    ),
                    const SizedBox(height: 12),
                    BrandPrimaryButton(
                      label: 'Обновить пароль',
                      onPressed: _changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              BrandSettingsGroup(
                header: 'Данные',
                children: [
                  BrandSettingsRow(
                    label: 'Экспорт данных',
                    onTap: () {},
                  ),
                  BrandSettingsRow(
                    label: 'Удалить аккаунт',
                    danger: true,
                    onTap: () {},
                    last: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
