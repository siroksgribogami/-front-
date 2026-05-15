import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _moderationEnabled = true;
  bool _warehouseAccess = false;
  bool _broadcastEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moderationEnabled = prefs.getBool('admin_moderation') ?? true;
      _warehouseAccess = prefs.getBool('admin_warehouse') ?? false;
      _broadcastEnabled = prefs.getBool('admin_broadcast') ?? false;
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
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;
    final textMain = isDark ? const Color(0xFFEAE8E4) : const Color(0xFF2A3A2C);
    return Scaffold(
      appBar: AppBar(title: const Text('Админ')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
            'Панель управления',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            color: cardBg,
            child: Column(
              children: [
                SwitchListTile(
                  value: _moderationEnabled,
                  onChanged: (v) {
                    setState(() => _moderationEnabled = v);
                    _save('admin_moderation', v);
                  },
                  title: const Text('Модерация заявок'),
                  subtitle: const Text('Ручная проверка новых проектов'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _warehouseAccess,
                  onChanged: (v) {
                    setState(() => _warehouseAccess = v);
                    _save('admin_warehouse', v);
                  },
                  title: const Text('Управление складом'),
                  subtitle: const Text('Доступ к разделу материалов и остатков'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _broadcastEnabled,
                  onChanged: (v) {
                    setState(() => _broadcastEnabled = v);
                    _save('admin_broadcast', v);
                  },
                  title: const Text('Рассылки пользователям'),
                  subtitle: const Text('Отправка сервисных уведомлений'),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
