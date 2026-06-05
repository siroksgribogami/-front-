import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';

/// Экран «Мои отклики» для мастера (сохраняется на устройстве).
class MasterMyBidsScreen extends StatefulWidget {
  const MasterMyBidsScreen({super.key});

  @override
  State<MasterMyBidsScreen> createState() => _MasterMyBidsScreenState();
}

class _MasterMyBidsScreenState extends State<MasterMyBidsScreen> {
  List<MasterMyBidRecord> _bids = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await MarketplaceLocalStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _bids = List.from(MarketplaceLocalStore.instance.myMasterBids);
      _loading = false;
    });
  }

  int get _activeCount =>
      _bids.where((b) => !_isDeclined(b.state)).length;

  int get _inWorkCount => _bids
      .where((b) => b.state.toLowerCase().contains('выбран'))
      .length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: BrandColors.canvas,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final subtitle = _bids.isEmpty
        ? 'Пока нет откликов'
        : '$_activeCount активных · $_inWorkCount в работе';

    return ColoredBox(
      color: BrandColors.canvas,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(BrandUi.pad, 8, BrandUi.pad, 24),
            children: [
              BrandAppBar(
                title: 'Мои отклики',
                subtitle: subtitle,
                big: true,
              ),
              const SizedBox(height: 4),
              if (_bids.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Пока нет откликов. Откройте ленту заказов и нажмите «Откликнуться».',
                      textAlign: TextAlign.center,
                      style: BrandUi.inter(
                        color: BrandColors.tar.withOpacity(0.45),
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              else
                ..._bids.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _BidCard(bid: b),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isDeclined(String state) {
  final s = state.toLowerCase();
  return s.contains('отклон') || s.contains('не выбран');
}

BrandStatusKind _statusKindFor(String state) {
  final s = state.toLowerCase();
  if (s.contains('выбран') && !s.contains('не')) {
    return BrandStatusKind.gold;
  }
  if (s.contains('отклон') || s.contains('не выбран')) {
    return BrandStatusKind.draft;
  }
  if (s.contains('отправ') || s.contains('рассмотр') || s.contains('просмотр')) {
    return BrandStatusKind.active;
  }
  return BrandStatusKind.active;
}

String _statusLabelFor(String state) {
  final s = state.toLowerCase();
  if (s.contains('выбран') && !s.contains('не')) return 'Выбран';
  if (s.contains('не выбран') || s.contains('отклон')) return 'Не выбран';
  if (s.contains('рассмотр') || s.contains('просмотр')) return 'На рассмотрении';
  if (s.contains('отправ')) return 'Отправлен';
  return state;
}

String _footerHintFor(String state) {
  final s = state.toLowerCase();
  if (s.contains('выбран') && !s.contains('не')) {
    return 'Заказчик подтвердил';
  }
  if (s.contains('не выбран') || s.contains('отклон')) {
    return 'Заказчик выбрал другого';
  }
  if (s.contains('отправ')) return 'Ждём ответа';
  return state;
}

class _BidCard extends StatelessWidget {
  const _BidCard({required this.bid});

  final MasterMyBidRecord bid;

  @override
  Widget build(BuildContext context) {
    final kind = _statusKindFor(bid.state);
    final statusLabel = _statusLabelFor(bid.state);
    final footerHint = _footerHintFor(bid.state);

    return Material(
      color: BrandColors.milk,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrandColors.borderSubtle),
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
                          bid.projectTitle,
                          style: pochaevsk(
                            fontSize: 18,
                            color: BrandColors.tar,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BrandStatus(label: statusLabel, kind: kind),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: BrandColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        footerHint,
                        style: BrandUi.inter(
                          fontSize: 12.5,
                          color: BrandColors.tar.withOpacity(0.55),
                        ),
                      ),
                    ),
                    Text(
                      bid.price,
                      style: pochaevsk(
                        fontSize: 18,
                        color: BrandColors.needles,
                        height: 1,
                      ),
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
