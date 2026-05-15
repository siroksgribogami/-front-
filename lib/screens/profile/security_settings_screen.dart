import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../config/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('Безопасность')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
            elevation: 0,
            color: cardBg,
            child: Column(
              children: [
                SwitchListTile(
                  value: _biometric,
                  onChanged: (v) {
                    setState(() => _biometric = v);
                    _saveBool('security_biometric', v);
                  },
                  activeColor: AppTheme.primaryColor,
                  title: const Text('Биометрия'),
                  subtitle: const Text('Вход по отпечатку/Face ID (если доступно)'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _sessionLock,
                  onChanged: (v) {
                    setState(() => _sessionLock = v);
                    _saveBool('security_session_lock', v);
                  },
                  activeColor: AppTheme.primaryColor,
                  title: const Text('Блокировка сессии'),
                  subtitle: const Text('Запрашивать вход после бездействия'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сменить пароль',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _oldCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Текущий пароль'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Новый пароль'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Подтверждение'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _changePassword,
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('Обновить пароль'),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
