import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';

enum _CatalogFilter { all, materials, rentals }

/// Каталог для мастера: материалы для закупки и аренда инструмента.
class MasterSuppliesCatalogScreen extends StatefulWidget {
  const MasterSuppliesCatalogScreen({super.key});

  @override
  State<MasterSuppliesCatalogScreen> createState() =>
      _MasterSuppliesCatalogScreenState();
}

class _MasterSuppliesCatalogScreenState
    extends State<MasterSuppliesCatalogScreen> {
  _CatalogFilter _filter = _CatalogFilter.all;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<_MaterialItem> _materials = [
    _MaterialItem(
      title: 'Гипсокартон Knauf 12.5 мм',
      subtitle: 'Лист 2.5×1.2 м · 1 шт',
      price: 'от 480 ₽',
      vendor: 'Леруа Мерлен',
      imageLabel: 'гкл',
    ),
    _MaterialItem(
      title: 'Краска Tikkurila Joker база А',
      subtitle: '2.7 л, матовая, под колеровку',
      price: 'от 3 290 ₽',
      vendor: 'Petrovich',
      imageLabel: 'краска',
    ),
    _MaterialItem(
      title: 'Кабель ВВГнг 3×2.5',
      subtitle: 'Бухта 100 м, ГОСТ',
      price: 'от 8 400 ₽',
      vendor: 'СтройМаркет',
      imageLabel: 'кабель',
    ),
    _MaterialItem(
      title: 'Плиточный клей Ceresit CM 11',
      subtitle: 'Мешок 25 кг',
      price: 'от 690 ₽',
      vendor: 'Леруа Мерлен',
      imageLabel: 'плитка',
    ),
    _MaterialItem(
      title: 'Ламинат Quick-Step Eligna',
      subtitle: '8 мм, 1 м² · 32 класс',
      price: 'от 1 850 ₽',
      vendor: 'Floorshop',
      imageLabel: 'пол',
    ),
  ];

  static const List<_RentalItem> _rentals = [
    _RentalItem(
      title: 'Перфоратор Bosch GBH 2-26',
      subtitle: 'SDS-Plus, 830 Вт',
      price: 'от 600 ₽/сутки',
      depositLabel: 'залог 5 000 ₽',
      imageLabel: 'инструмент',
    ),
    _RentalItem(
      title: 'Виброшлифмашина Makita BO3711',
      subtitle: 'Орбитальная, 190 Вт',
      price: 'от 450 ₽/сутки',
      depositLabel: 'залог 3 000 ₽',
      imageLabel: 'шлифмашина',
    ),
    _RentalItem(
      title: 'Лазерный нивелир Bosch GLL 3-80',
      subtitle: '3 плоскости, штатив в комплекте',
      price: 'от 950 ₽/сутки',
      depositLabel: 'залог 8 000 ₽',
      imageLabel: 'нивелир',
    ),
    _RentalItem(
      title: 'Строительный пылесос Karcher NT 30/1',
      subtitle: '30 л, мокрая/сухая уборка',
      price: 'от 700 ₽/сутки',
      depositLabel: 'залог 4 500 ₽',
      imageLabel: 'пылесос',
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
    final materials = _materials.where(_matchesMaterial).toList();
    final rentals = _rentals.where(_matchesRental).toList();
    final showMaterials =
        _filter == _CatalogFilter.all || _filter == _CatalogFilter.materials;
    final showRentals =
        _filter == _CatalogFilter.all || _filter == _CatalogFilter.rentals;

    final items = <Widget>[];
    if (showMaterials) {
      items.addAll(materials.map((m) => _CatalogRow.material(m)));
    }
    if (showRentals) {
      items.addAll(rentals.map((r) => _CatalogRow.rental(r)));
    }

    return ColoredBox(
      color: BrandRuntime.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
              child: BrandAppBar(
                title: 'Материалы',
                big: true,
                actions: BrandIconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: BrandRuntime.ink.withOpacity(0.55),
                  ),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Поиск'),
                        content: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: BrandUi.inputDecoration(hint: 'Поиск'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Готово'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(BrandUi.pad, 0, BrandUi.pad, 8),
                child: Text(
                  'Поиск: «${_searchController.text}»',
                  style: BrandUi.inter(
                    fontSize: 12.5,
                    color: BrandRuntime.ink.withOpacity(0.55),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(BrandUi.pad, 0, BrandUi.pad, 12),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    BrandChip(
                      label: 'Всё',
                      selected: _filter == _CatalogFilter.all,
                      onTap: () => setState(() => _filter = _CatalogFilter.all),
                    ),
                    const SizedBox(width: 8),
                    BrandChip(
                      label: 'Материалы',
                      selected: _filter == _CatalogFilter.materials,
                      onTap: () =>
                          setState(() => _filter = _CatalogFilter.materials),
                    ),
                    const SizedBox(width: 8),
                    BrandChip(
                      label: 'Аренда инструмента',
                      selected: _filter == _CatalogFilter.rentals,
                      onTap: () =>
                          setState(() => _filter = _CatalogFilter.rentals),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Ничего не нашли. Попробуйте другой запрос.',
                          textAlign: TextAlign.center,
                          style: BrandUi.inter(
                            color: BrandRuntime.ink.withOpacity(0.55),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        BrandUi.pad,
                        0,
                        BrandUi.pad,
                        24,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 11),
                      itemBuilder: (_, i) => items[i],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialItem {
  final String title;
  final String subtitle;
  final String price;
  final String vendor;
  final String imageLabel;

  const _MaterialItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.vendor,
    required this.imageLabel,
  });
}

class _RentalItem {
  final String title;
  final String subtitle;
  final String price;
  final String depositLabel;
  final String imageLabel;

  const _RentalItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.depositLabel,
    required this.imageLabel,
  });
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.title,
    required this.price,
    required this.imageLabel,
    required this.tag,
    required this.isRental,
    this.subtitle,
  });

  factory _CatalogRow.material(_MaterialItem m) {
    return _CatalogRow(
      title: m.title,
      subtitle: m.subtitle,
      price: m.price,
      imageLabel: m.imageLabel,
      tag: 'Материал',
      isRental: false,
    );
  }

  factory _CatalogRow.rental(_RentalItem r) {
    return _CatalogRow(
      title: r.title,
      subtitle: r.subtitle,
      price: r.price,
      imageLabel: r.imageLabel,
      tag: 'Аренда',
      isRental: true,
    );
  }

  final String title;
  final String? subtitle;
  final String price;
  final String imageLabel;
  final String tag;
  final bool isRental;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandRuntime.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isRental ? 'Бронирование: $title' : 'Откроем закупку: $title')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandRuntime.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: BrandStripedPlaceholder(
                    label: imageLabel,
                    height: 64,
                    radius: 12,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isRental
                              ? BrandColors.sandstone
                              : BrandRuntime.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: BrandUi.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isRental
                                ? BrandColors.surik
                                : BrandRuntime.needles,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: BrandUi.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: pochaevsk(
                          fontSize: 17,
                          color: BrandRuntime.needles,
                          height: 1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: BrandUi.inter(
                            fontSize: 11.5,
                            color: BrandRuntime.ink.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BrandRuntime.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: BrandRuntime.needles,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
