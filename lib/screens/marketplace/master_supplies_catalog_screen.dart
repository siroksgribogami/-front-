import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';

/// Каталог для мастера: материалы для закупки и аренда инструмента.
class MasterSuppliesCatalogScreen extends StatefulWidget {
  const MasterSuppliesCatalogScreen({super.key});

  @override
  State<MasterSuppliesCatalogScreen> createState() =>
      _MasterSuppliesCatalogScreenState();
}

class _MasterSuppliesCatalogScreenState
    extends State<MasterSuppliesCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const List<_MaterialItem> _materials = [
    _MaterialItem(
      title: 'Гипсокартон Knauf 12.5 мм',
      subtitle: 'Лист 2.5×1.2 м · 1 шт',
      price: 'от 480 ₽',
      vendor: 'Леруа Мерлен',
      icon: Icons.layers_outlined,
    ),
    _MaterialItem(
      title: 'Краска Tikkurila Joker база А',
      subtitle: '2.7 л, матовая, под колеровку',
      price: 'от 3 290 ₽',
      vendor: 'Petrovich',
      icon: Icons.format_paint_outlined,
    ),
    _MaterialItem(
      title: 'Кабель ВВГнг 3×2.5',
      subtitle: 'Бухта 100 м, ГОСТ',
      price: 'от 8 400 ₽',
      vendor: 'СтройМаркет',
      icon: Icons.cable_outlined,
    ),
    _MaterialItem(
      title: 'Плиточный клей Ceresit CM 11',
      subtitle: 'Мешок 25 кг',
      price: 'от 690 ₽',
      vendor: 'Леруа Мерлен',
      icon: Icons.grid_4x4_outlined,
    ),
    _MaterialItem(
      title: 'Ламинат Quick-Step Eligna',
      subtitle: '8 мм, 1 м² · 32 класс',
      price: 'от 1 850 ₽',
      vendor: 'Floorshop',
      icon: Icons.view_quilt_outlined,
    ),
  ];

  static const List<_RentalItem> _rentals = [
    _RentalItem(
      title: 'Перфоратор Bosch GBH 2-26',
      subtitle: 'SDS-Plus, 830 Вт',
      price: 'от 600 ₽/сутки',
      depositLabel: 'залог 5 000 ₽',
      icon: Icons.handyman_outlined,
    ),
    _RentalItem(
      title: 'Виброшлифмашина Makita BO3711',
      subtitle: 'Орбитальная, 190 Вт',
      price: 'от 450 ₽/сутки',
      depositLabel: 'залог 3 000 ₽',
      icon: Icons.build_circle_outlined,
    ),
    _RentalItem(
      title: 'Лазерный нивелир Bosch GLL 3-80',
      subtitle: '3 плоскости, штатив в комплекте',
      price: 'от 950 ₽/сутки',
      depositLabel: 'залог 8 000 ₽',
      icon: Icons.precision_manufacturing_outlined,
    ),
    _RentalItem(
      title: 'Строительный пылесос Karcher NT 30/1',
      subtitle: '30 л, мокрая/сухая уборка',
      price: 'от 700 ₽/сутки',
      depositLabel: 'залог 4 500 ₽',
      icon: Icons.cleaning_services_outlined,
    ),
  ];

  bool _matchesMaterial(_MaterialItem m) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return m.title.toLowerCase().contains(q) ||
        m.subtitle.toLowerCase().contains(q) ||
        m.vendor.toLowerCase().contains(q);
  }

  bool _matchesRental(_RentalItem r) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return r.title.toLowerCase().contains(q) ||
        r.subtitle.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final border = MarketplaceColors.textMutedFor(context).withOpacity(0.22);

    final materials = _materials.where(_matchesMaterial).toList();
    final rentals = _rentals.where(_matchesRental).toList();

    final searchField = TextField(
      controller: _searchController,
      style: TextStyle(fontSize: 13, color: textPrimary),
      decoration: InputDecoration(
        hintText: 'Поиск',
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: card,
        prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: MarketplaceColors.bluePrimary.withOpacity(0.8)),
        ),
      ),
    );

    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 14, horizontalPad, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Каталог',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTextStyle.fontFamily,
                          color: textPrimary,
                          height: AppTextStyle.defaultHeight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      searchField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Каталог',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppTextStyle.fontFamily,
                        color: textPrimary,
                        height: AppTextStyle.defaultHeight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: searchField),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            child: Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 1),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: MarketplaceColors.bluePrimary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: textMuted,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                tabs: const [
                  Tab(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 14),
                        SizedBox(width: 4),
                        Text('Материалы'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.handyman_outlined, size: 14),
                        SizedBox(width: 4),
                        Text('Аренда'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MaterialsList(
                  items: materials,
                  card: card,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  border: border,
                ),
                _RentalsList(
                  items: rentals,
                  card: card,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  border: border,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialItem {
  final String title;
  final String subtitle;
  final String price;
  final String vendor;
  final IconData icon;

  const _MaterialItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.vendor,
    required this.icon,
  });
}

class _RentalItem {
  final String title;
  final String subtitle;
  final String price;
  final String depositLabel;
  final IconData icon;

  const _RentalItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.depositLabel,
    required this.icon,
  });
}

class _MaterialsList extends StatelessWidget {
  final List<_MaterialItem> items;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  const _MaterialsList({
    required this.items,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ничего не нашли. Попробуйте другой запрос.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }
    final pad = MarketplaceColors.horizontalPaddingFor(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = items[i];
        return Material(
          color: card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Откроем закупку: ${m.title}')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MarketplaceColors.bluePrimary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(m.icon,
                        color: MarketplaceColors.bluePrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.subtitle,
                          style: TextStyle(
                              color: textSecondary, fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.vendor,
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    m.price,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RentalsList extends StatelessWidget {
  final List<_RentalItem> items;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  const _RentalsList({
    required this.items,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ничего не нашли. Попробуйте другой запрос.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }
    final pad = MarketplaceColors.horizontalPaddingFor(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = items[i];
        return Material(
          color: card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Бронирование: ${r.title}')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MarketplaceColors.aiTurquoise.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(r.icon,
                        color: MarketplaceColors.aiTurquoise, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.subtitle,
                          style: TextStyle(
                              color: textSecondary, fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.depositLabel,
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    r.price,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
