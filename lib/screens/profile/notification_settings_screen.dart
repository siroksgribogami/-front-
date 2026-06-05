import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../config/brand_colors.dart';
import '../../core/theme/brand_ui.dart';

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

  Widget _settingsIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: BrandColors.linen.withOpacity(0.7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: BrandColors.needles),
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
        backgroundColor: BrandColors.canvas,
        foregroundColor: BrandColors.tar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: BrandAppBar(
            title: 'Уведомления',
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
                header: 'Push-уведомления',
                children: [
                  BrandSettingsRow(
                    icon: _settingsIcon(Icons.notifications_outlined),
                    label: 'Разрешить push',
                    trailing: BrandToggle(
                      value: _pushEnabled,
                      onChanged: (v) {
                        setState(() => _pushEnabled = v);
                        _save('notif_push', v);
                      },
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    icon: _settingsIcon(Icons.chat_bubble_outline_rounded),
                    label: 'Новые сообщения',
                    trailing: BrandToggle(
                      value: _chatEnabled,
                      onChanged: _pushEnabled
                          ? (v) {
                              setState(() => _chatEnabled = v);
                              _save('notif_chat', v);
                            }
                          : null,
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    icon: _settingsIcon(Icons.bookmark_outline_rounded),
                    label: 'Отклики и сметы',
                    trailing: BrandToggle(
                      value: _projectEnabled,
                      onChanged: _pushEnabled
                          ? (v) {
                              setState(() => _projectEnabled = v);
                              _save('notif_project', v);
                            }
                          : null,
                    ),
                    showChevron: false,
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              BrandSettingsGroup(
                header: 'По проектам',
                children: [
                  BrandSettingsRow(
                    label: 'Изменения статуса',
                    trailing: BrandToggle(
                      value: _projectEnabled,
                      onChanged: _pushEnabled
                          ? (v) {
                              setState(() => _projectEnabled = v);
                              _save('notif_project', v);
                            }
                          : null,
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    label: 'Этапы и сроки',
                    trailing: BrandToggle(
                      value: _projectEnabled,
                      onChanged: _pushEnabled
                          ? (v) {
                              setState(() => _projectEnabled = v);
                              _save('notif_project', v);
                            }
                          : null,
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    label: 'Готов 3D / визуализация',
                    trailing: BrandToggle(
                      value: false,
                      onChanged: null,
                    ),
                    showChevron: false,
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              BrandSettingsGroup(
                header: 'Прочее',
                children: [
                  BrandSettingsRow(
                    label: 'Акции и новости',
                    trailing: BrandToggle(
                      value: _promoEnabled,
                      onChanged: _pushEnabled
                          ? (v) {
                              setState(() => _promoEnabled = v);
                              _save('notif_promo', v);
                            }
                          : null,
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    label: 'Email-дайджест',
                    trailing: BrandToggle(
                      value: _promoEnabled,
                      onChanged: _pushEnabled
                          ? (v) {
                              setState(() => _promoEnabled = v);
                              _save('notif_promo', v);
                            }
                          : null,
                    ),
                    showChevron: false,
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
