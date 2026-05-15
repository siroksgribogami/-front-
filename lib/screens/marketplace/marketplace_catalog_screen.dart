import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/services_furniture.dart';
import '../chat/furniture_tab.dart';
import '../chat/services_tab.dart';

/// Раздел каталога маркетплейса: услуги и мебель отдельно от переписок.
class MarketplaceCatalogScreen extends StatefulWidget {
  const MarketplaceCatalogScreen({super.key});

  @override
  State<MarketplaceCatalogScreen> createState() =>
      _MarketplaceCatalogScreenState();
}

class _MarketplaceCatalogScreenState extends State<MarketplaceCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  String _region = 'Все регионы';
  String _sortBy = 'Рейтинг';
  String _priceRange = 'Любая';

  static const _regions = [
    'Все регионы',
    'Москва',
    'Московская область',
    'Санкт-Петербург',
    'Казань',
  ];

  static const _sorts = ['Рейтинг', 'Цена ↑', 'Цена ↓'];
  static const _prices = ['Любая', 'до 20 000 ₽', '20 000–40 000 ₽', 'от 40 000 ₽'];

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

  bool get _filtersActive =>
      _region != 'Все регионы' ||
      _priceRange != 'Любая' ||
      _sortBy != 'Рейтинг';

  void _openFilterSheet() {
    var region = _region;
    var sortBy = _sortBy;
    var priceRange = _priceRange;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final bg = MarketplaceColors.backgroundFor(ctx);
        final card = MarketplaceColors.cardFor(ctx);
        final textPrimary = MarketplaceColors.textPrimaryFor(ctx);
        final divider = MarketplaceColors.textMutedFor(ctx).withOpacity(0.22);

        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: SafeArea(
              child: Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Фильтры каталога',
                      style: TextStyle(
                        fontFamily: AppTextStyle.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: region,
                      dropdownColor: card,
                      decoration: InputDecoration(
                        labelText: 'Регион',
                        filled: true,
                        fillColor: card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: divider),
                        ),
                      ),
                      items: _regions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setModal(() => region = v ?? region),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priceRange,
                      dropdownColor: card,
                      decoration: InputDecoration(
                        labelText: 'Цена',
                        filled: true,
                        fillColor: card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: divider),
                        ),
                      ),
                      items: _prices
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setModal(() => priceRange = v ?? priceRange),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: sortBy,
                      dropdownColor: card,
                      decoration: InputDecoration(
                        labelText: 'Сортировка',
                        filled: true,
                        fillColor: card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: divider),
                        ),
                      ),
                      items: _sorts
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setModal(() => sortBy = v ?? sortBy),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setModal(() {
                            region = 'Все регионы';
                            priceRange = 'Любая';
                            sortBy = 'Рейтинг';
                          }),
                          child: const Text('Сбросить'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _region = region;
                              _priceRange = priceRange;
                              _sortBy = sortBy;
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: MarketplaceColors.bluePrimary,
                          ),
                          child: const Text('Применить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _matchesSearchServices(ServiceCompany s) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return s.name.toLowerCase().contains(q) ||
        s.category.toLowerCase().contains(q) ||
        s.description.toLowerCase().contains(q);
  }

  bool _matchesSearchFurniture(FurnitureItem f) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return f.name.toLowerCase().contains(q) ||
        f.category.toLowerCase().contains(q) ||
        f.description.toLowerCase().contains(q) ||
        f.material.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices();
    final furniture = _filteredFurniture();
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final border = MarketplaceColors.textMutedFor(context).withOpacity(0.22);

    final searchField = TextField(
      controller: _searchController,
      style: TextStyle(fontSize: 13, color: textPrimary),
      decoration: InputDecoration(
        hintText: 'Поиск',
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          borderSide:
              BorderSide(color: MarketplaceColors.bluePrimary.withOpacity(0.8)),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Каталог',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: AppTextStyle.fontFamily,
                                color: textPrimary,
                                height: AppTextStyle.defaultHeight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _openFilterSheet,
                            icon: Badge(
                              isLabelVisible: _filtersActive,
                              smallSize: 6,
                              child: Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: textSecondary,
                              ),
                            ),
                            label: Text(
                              'Фильтр',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
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
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _openFilterSheet,
                      icon: Badge(
                        isLabelVisible: _filtersActive,
                        smallSize: 6,
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: textSecondary,
                        ),
                      ),
                      label: Text(
                        'Фильтр',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                tabs: [
                  Tab(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.build_outlined, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Услуги',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chair_outlined, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Мебель',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
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
                ServicesTab(items: services),
                FurnitureTab(items: furniture),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ServiceCompany> _filteredServices() {
    final filtered = catalogServices.where((s) {
      final regionOk = _region == 'Все регионы' || s.region == _region;
      final priceOk = switch (_priceRange) {
        'до 20 000 ₽' => s.minPrice <= 20000,
        '20 000–40 000 ₽' => s.minPrice > 20000 && s.minPrice <= 40000,
        'от 40 000 ₽' => s.minPrice > 40000,
        _ => true,
      };
      return regionOk && priceOk && _matchesSearchServices(s);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Цена ↑':
          return a.minPrice.compareTo(b.minPrice);
        case 'Цена ↓':
          return b.minPrice.compareTo(a.minPrice);
        default:
          return b.rating.compareTo(a.rating);
      }
    });
    return filtered;
  }

  List<FurnitureItem> _filteredFurniture() {
    final filtered = catalogFurniture.where((f) {
      final regionOk = _region == 'Все регионы' || f.region == _region;
      final priceOk = switch (_priceRange) {
        'до 20 000 ₽' => f.price <= 20000,
        '20 000–40 000 ₽' => f.price > 20000 && f.price <= 40000,
        'от 40 000 ₽' => f.price > 40000,
        _ => true,
      };
      return regionOk && priceOk && _matchesSearchFurniture(f);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Цена ↑':
          return a.price.compareTo(b.price);
        case 'Цена ↓':
          return b.price.compareTo(a.price);
        default:
          return b.rating.compareTo(a.rating);
      }
    });
    return filtered;
  }
}
