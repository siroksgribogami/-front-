import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_local_store.dart';
import 'master_order_detail_screen.dart';

/// Лента опубликованных проектов заказчиков (мастер).
class MasterOrdersFeedScreen extends StatefulWidget {
  const MasterOrdersFeedScreen({super.key});

  @override
  State<MasterOrdersFeedScreen> createState() => _MasterOrdersFeedScreenState();
}

class _MasterOrdersFeedScreenState extends State<MasterOrdersFeedScreen> {
  /// `null` — все районы; иначе подстрока в [OrderFeedItem.district].
  String? _districtToken;
  String? _workType;

  List<OrderFeedItem> _orderFeed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await MarketplaceLocalStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _orderFeed = List.from(MarketplaceLocalStore.instance.orderFeed);
      _loading = false;
    });
  }

  List<OrderFeedItem> get _filtered {
    var list = List<OrderFeedItem>.from(_orderFeed);
    if (_districtToken != null) {
      list = list.where((e) => e.district.contains(_districtToken!)).toList();
    }
    if (_workType != null) {
      list = list.where((e) => e.workType == _workType).toList();
    }
    return list;
  }

  void _toggleDistrict(String? token) {
    setState(() => _districtToken = _districtToken == token ? null : token);
  }

  void _toggleWork(String? w) {
    setState(() => _workType = _workType == w ? null : w);
  }

  Future<void> _openRespond(OrderFeedItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MasterOrderDetailScreen(item: item),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ColoredBox(
        color: BrandRuntime.canvas,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filtered;
    final all = _orderFeed;
    final workTypes = all.map((e) => e.workType).toSet().toList();
    final auth = context.watch<AuthProvider>();
    final masterName = auth.user?.visibleName.trim().isNotEmpty == true
        ? auth.user!.visibleName
        : 'Мастер';

    return ColoredBox(
      color: BrandRuntime.canvas,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(BrandUi.pad, 8, BrandUi.pad, 24),
            children: [
              BrandAppBar(
                kicker: '$masterName · Мастер',
                title: 'Лента заказов',
                big: true,
                actions: BrandIconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: BrandRuntime.ink.withOpacity(0.55),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    BrandChip(
                      label: 'Все районы',
                      selected: _districtToken == null,
                      onTap: () => _toggleDistrict(null),
                    ),
                    const SizedBox(width: 8),
                    BrandChip(
                      label: 'САО',
                      selected: _districtToken == 'САО',
                      onTap: () => _toggleDistrict('САО'),
                    ),
                    const SizedBox(width: 8),
                    BrandChip(
                      label: 'ЗАО',
                      selected: _districtToken == 'ЗАО',
                      onTap: () => _toggleDistrict('ЗАО'),
                    ),
                    ...workTypes.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: BrandChip(
                          label: w,
                          selected: _workType == w,
                          onTap: () => _toggleWork(w),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Нет заявок по выбранным фильтрам',
                      style: BrandUi.inter(
                        color: BrandRuntime.ink.withOpacity(0.45),
                      ),
                    ),
                  ),
                )
              else
                ...items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeedCard(
                      item: e,
                      onRespond: () => _openRespond(e),
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

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.onRespond,
  });

  final OrderFeedItem item;
  final VoidCallback onRespond;

  String get _areaLabel {
    final short = item.addressShort.trim();
    if (short.isEmpty) return item.district;
    final district = item.district.replaceAll('Москва, ', '');
    return '$district · $short';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandRuntime.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onRespond,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandRuntime.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.workType,
                            style: pochaevsk(
                              fontSize: 19,
                              color: BrandRuntime.ink,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: BrandRuntime.ink.withOpacity(0.35),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _areaLabel,
                                  style: BrandUi.inter(
                                    fontSize: 13,
                                    color: BrandRuntime.ink.withOpacity(0.55),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (item.has3d)
                      const BrandStatus(label: 'Новый', kind: BrandStatusKind.market)
                    else
                      Text(
                        'недавно',
                        style: BrandUi.inter(
                          fontSize: 12,
                          color: BrandRuntime.ink.withOpacity(0.35),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: BrandRuntime.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.workType,
                    style: BrandUi.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: BrandRuntime.needles,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.only(top: 13),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: BrandRuntime.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'БЮДЖЕТ',
                              style: BrandUi.inter(
                                fontSize: 10.5,
                                color: BrandRuntime.ink.withOpacity(0.35),
                              ).copyWith(letterSpacing: 0.4),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.budgetLabel,
                              style: pochaevsk(
                                fontSize: 19,
                                color: BrandRuntime.needles,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: BrandRuntime.border,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'СРОК',
                            style: BrandUi.inter(
                              fontSize: 10.5,
                              color: BrandRuntime.ink.withOpacity(0.35),
                            ).copyWith(letterSpacing: 0.4),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'По ТЗ',
                            style: pochaevsk(
                              fontSize: 19,
                              color: BrandRuntime.ink,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: BrandColors.clay,
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          onTap: onRespond,
                          borderRadius: BorderRadius.circular(11),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            child: Text(
                              'Откликнуться',
                              style: BrandUi.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.onClay,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
