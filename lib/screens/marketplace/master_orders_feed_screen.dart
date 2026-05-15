import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/marketplace_project.dart';
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
        color: MarketplaceColors.backgroundFor(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filtered;
    final all = _orderFeed;
    final workTypes = all.map((e) => e.workType).toSet().toList();
    final bg = MarketplaceColors.backgroundFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    final Widget listInner = RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 24),
            children: [
              Text(
                'Лента заказов',
                style: TextStyle(
                  fontFamily: AppTextStyle.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'В ленту попало ${all.length} заявок. Потяните вниз, чтобы обновить.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Район',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChipStyled(
                    label: 'САО',
                    selected: _districtToken == 'САО',
                    onTap: () => _toggleDistrict('САО'),
                  ),
                  _FilterChipStyled(
                    label: 'ЗАО',
                    selected: _districtToken == 'ЗАО',
                    onTap: () => _toggleDistrict('ЗАО'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Тип работ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: workTypes
                    .map(
                      (w) => _FilterChipStyled(
                        label: w,
                        selected: _workType == w,
                        onTap: () => _toggleWork(w),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Нет заявок по выбранным фильтрам',
                      style: TextStyle(color: textMuted),
                    ),
                  ),
                )
              else
                ...items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeedCard(
                      item: e,
                      onTap: () => _openRespond(e),
                    ),
                  ),
                ),
            ],
          ),
        );

    return ColoredBox(
      color: bg,
      child: SafeArea(child: listInner),
    );
  }
}

/// Собственная «таблетка» без темы Chip — одинаково читается в светлой и тёмной теме.
class _FilterChipStyled extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipStyled({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final surface = MarketplaceColors.surfaceFor(context);
    final border = MarketplaceColors.textMutedFor(context).withOpacity(selected ? 0.45 : 0.28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? MarketplaceColors.bluePrimary.withOpacity(0.22)
                : surface.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color:
                  selected ? MarketplaceColors.bluePrimary : border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? MarketplaceColors.bluePrimary : textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final OrderFeedItem item;
  final VoidCallback onTap;

  const _FeedCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final borderMuted = MarketplaceColors.textMutedFor(context).withOpacity(
      Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.12,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MarketplaceColors.bluePrimary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.workType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MarketplaceColors.bluePrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.has3d)
                    Row(
                      children: [
                        Icon(
                          Icons.view_in_ar_rounded,
                          size: 18,
                          color: textSecondary.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '3D',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.budgetLabel,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ориентировочный бюджет',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.district} · ${item.addressShort}',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.teaser,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

