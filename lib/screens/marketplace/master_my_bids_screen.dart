import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    if (_loading) {
      return ColoredBox(
        color: bg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 24),
            children: [
              Text(
                'Мои отклики',
                style: TextStyle(
                  fontFamily: AppTextStyle.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Предложения, которые вы отправляли по заявкам из ленты. Данные хранятся в приложении.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (_bids.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Пока нет откликов. Откройте ленту заказов и нажмите «Откликнуться».',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textMuted, height: 1.4),
                    ),
                  ),
                )
              else
                ..._bids.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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

class _BidCard extends StatelessWidget {
  final MasterMyBidRecord bid;

  const _BidCard({required this.bid});

  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bid.projectTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bid.price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MarketplaceColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bid.state,
              style: TextStyle(
                fontSize: 13,
                color: bid.state.contains('Отклон')
                    ? MarketplaceColors.statusDeclined
                    : textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
