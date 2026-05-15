import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../config/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _chatEnabled = true;
  bool _projectEnabled = true;
  bool _promoEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _chatEnabled = prefs.getBool('notif_chat') ?? true;
      _projectEnabled = prefs.getBool('notif_project') ?? true;
      _promoEnabled = prefs.getBool('notif_promo') ?? false;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSub = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки уведомлений')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile(
            title: 'Push-уведомления',
            subtitle: 'Общий переключатель уведомлений',
            value: _pushEnabled,
            textMain: textMain,
            textSub: textSub,
            cardBg: cardBg,
            onChanged: (v) {
              setState(() => _pushEnabled = v);
              _save('notif_push', v);
            },
              ),
              _tile(
            title: 'Чаты',
            subtitle: 'Новые входящие чаты и ответы мастеров',
            value: _chatEnabled,
            textMain: textMain,
            textSub: textSub,
            cardBg: cardBg,
            onChanged: _pushEnabled
                ? (v) {
                    setState(() => _chatEnabled = v);
                    _save('notif_chat', v);
                  }
                : null,
              ),
              _tile(
            title: 'Проекты и отклики',
            subtitle: 'Изменения статуса проекта и новые отклики',
            value: _projectEnabled,
            textMain: textMain,
            textSub: textSub,
            cardBg: cardBg,
            onChanged: _pushEnabled
                ? (v) {
                    setState(() => _projectEnabled = v);
                    _save('notif_project', v);
                  }
                : null,
              ),
              _tile(
            title: 'Акции и подборки',
            subtitle: 'Промо и рекомендации от платформы',
            value: _promoEnabled,
            textMain: textMain,
            textSub: textSub,
            cardBg: cardBg,
            onChanged: _pushEnabled
                ? (v) {
                    setState(() => _promoEnabled = v);
                    _save('notif_promo', v);
                  }
                : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required bool value,
    required Color textMain,
    required Color textSub,
    required Color cardBg,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      elevation: 0,
      color: cardBg,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: textMain),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: textSub)),
      ),
    );
  }
}
