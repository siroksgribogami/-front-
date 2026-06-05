import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/services_furniture.dart';

/// Раздел каталога маркетплейса: услуги и мебель отдельно от переписок.
class MarketplaceCatalogScreen extends StatefulWidget {
  const MarketplaceCatalogScreen({super.key});

  @override
  State<MarketplaceCatalogScreen> createState() =>
      _MarketplaceCatalogScreenState();
}

class _MarketplaceCatalogScreenState extends State<MarketplaceCatalogScreen> {
  late final TextEditingController _searchController;

  int _tabIndex = 0;
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
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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
      backgroundColor: BrandColors.milk,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: SafeArea(
              child: Padding(
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
                          color: BrandColors.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Фильтры каталога',
                      style: BrandUi.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: region,
                      dropdownColor: BrandColors.milk,
                      decoration: BrandUi.inputDecoration(hint: 'Регион'),
                      items: _regions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setModal(() => region = v ?? region),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priceRange,
                      dropdownColor: BrandColors.milk,
                      decoration: BrandUi.inputDecoration(hint: 'Цена'),
                      items: _prices
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setModal(() => priceRange = v ?? priceRange),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: sortBy,
                      dropdownColor: BrandColors.milk,
                      decoration: BrandUi.inputDecoration(hint: 'Сортировка'),
                      items: _sorts
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setModal(() => sortBy = v ?? sortBy),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        BrandGhostButton(
                          label: 'Сбросить',
                          onPressed: () => setModal(() {
                            region = 'Все регионы';
                            priceRange = 'Любая';
                            sortBy = 'Рейтинг';
                          }),
                        ),
                        const Spacer(),
                        BrandPrimaryButton(
                          label: 'Применить',
                          expanded: false,
                          onPressed: () {
                            setState(() {
                              _region = region;
                              _priceRange = priceRange;
                              _sortBy = sortBy;
                            });
                            Navigator.of(ctx).pop();
                          },
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

  String _serviceLabel(ServiceCompany s) =>
      s.category.toLowerCase().split(' ').first;

  String _furnitureLabel(FurnitureItem f) =>
      f.name.toLowerCase().split(' ').first;

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices();
    final furniture = _filteredFurniture();
    final items = _tabIndex == 0 ? services : furniture;
    final isEmpty = items.isEmpty;

    return ColoredBox(
      color: BrandColors.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandAppBar(
              title: 'Каталог',
              big: true,
              actions: BrandIconButton(
                icon: Badge(
                  isLabelVisible: _filtersActive,
                  smallSize: 6,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: BrandColors.needles,
                  ),
                ),
                onPressed: _openFilterSheet,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrandSegmentedControl(
                    labels: const ['Услуги', 'Мебель'],
                    index: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                  const SizedBox(height: 12),
                  BrandSearchField(
                    controller: _searchController,
                    hint: 'Поиск по каталогу',
                  ),
                ],
              ),
            ),
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Text(
                        'Ничего не найдено по фильтрам',
                        style: BrandUi.inter(
                          color: BrandColors.tar.withOpacity(0.55),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 210,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        if (_tabIndex == 0) {
                          final s = services[index];
                          return _CatalogCard(
                            title: s.name,
                            price: s.priceRange,
                            tag: 'Услуга',
                            label: _serviceLabel(s),
                            isService: true,
                          );
                        }
                        final f = furniture[index];
                        return _CatalogCard(
                          title: f.name,
                          price: 'от ${NumberFormat('#,###', 'ru').format(f.price.round()).replaceAll(',', ' ')} ₽',
                          tag: 'Мебель',
                          label: _furnitureLabel(f),
                          isService: false,
                        );
                      },
                    ),
            ),
          ],
        ),
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

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.title,
    required this.price,
    required this.tag,
    required this.label,
    required this.isService,
  });

  final String title;
  final String price;
  final String tag;
  final String label;
  final bool isService;

  @override
  Widget build(BuildContext context) {
    final tagColor = isService ? BrandColors.needles : BrandColors.surik;

    return Container(
      decoration: BoxDecoration(
        color: BrandColors.milk,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              BrandStripedPlaceholder(
                label: label,
                height: 100,
                radius: 0,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: BrandUi.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.onNeedles,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BrandUi.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          style: pochaevsk(
                            fontSize: 16,
                            color: BrandColors.needles,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: BrandColors.linen,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: BrandColors.needles,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
