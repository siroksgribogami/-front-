import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../config/brand_colors.dart';
import '../../core/theme/brand_ui.dart';

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

  Widget _adminIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: BrandColors.sandstone,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: BrandColors.surik),
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
            title: 'Администрирование',
            subtitle: 'Доступ: модератор',
            onBack: () => Navigator.of(context).maybePop(),
            actions: const BrandStatus(
              label: 'Admin',
              kind: BrandStatusKind.market,
            ),
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
              Row(
                children: const [
                  Expanded(
                    child: BrandStatTile(
                      value: '12',
                      label: 'на модерации',
                      accent: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: BrandStatTile(
                      value: '284',
                      label: 'мастеров',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: BrandStatTile(
                      value: '1 940',
                      label: 'на складе',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BrandSettingsGroup(
                header: 'Модерация',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const BrandAvatar(
                              name: 'Денис Орлов',
                              size: 40,
                              radius: 12,
                              tone: BrandAvatarTone.clay,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Денис Орлов',
                                    style: BrandUi.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BrandColors.tar,
                                    ),
                                  ),
                                  Text(
                                    'Заявка мастера · электрика',
                                    style: BrandUi.inter(
                                      fontSize: 12,
                                      color: BrandColors.tar.withOpacity(0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: BrandColors.needles,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    child: Text(
                                      'Одобрить',
                                      textAlign: TextAlign.center,
                                      style: BrandUi.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: BrandColors.onNeedles,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Material(
                                color: BrandColors.milk,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: BrandColors.chipBorder,
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    child: Text(
                                      'Отклонить',
                                      textAlign: TextAlign.center,
                                      style: BrandUi.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: BrandColors.surik,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  BrandSettingsRow(
                    icon: _adminIcon(Icons.flag_outlined),
                    label: 'Жалобы на объявления',
                    value: '3',
                    onTap: () {},
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              BrandSettingsGroup(
                header: 'Склад и каталог',
                children: [
                  BrandSettingsRow(
                    icon: _adminIcon(Icons.inventory_2_outlined),
                    label: 'Остатки на складе',
                    value: '1 940 SKU',
                    trailing: BrandToggle(
                      value: _warehouseAccess,
                      onChanged: (v) {
                        setState(() => _warehouseAccess = v);
                        _save('admin_warehouse', v);
                      },
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    icon: _adminIcon(Icons.grid_view_rounded),
                    label: 'Управление каталогом',
                    trailing: BrandToggle(
                      value: _moderationEnabled,
                      onChanged: (v) {
                        setState(() => _moderationEnabled = v);
                        _save('admin_moderation', v);
                      },
                    ),
                    showChevron: false,
                  ),
                  BrandSettingsRow(
                    icon: _adminIcon(Icons.campaign_outlined),
                    label: 'Рассылки пользователям',
                    trailing: BrandToggle(
                      value: _broadcastEnabled,
                      onChanged: (v) {
                        setState(() => _broadcastEnabled = v);
                        _save('admin_broadcast', v);
                      },
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
