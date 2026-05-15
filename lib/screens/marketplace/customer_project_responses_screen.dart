import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../services/marketplace_local_store.dart';
import '../../models/marketplace_project.dart';
import 'contract_confirm_screen.dart';
import 'master_public_profile_screen.dart';

/// Отклики мастеров на проект заказчика.
class CustomerProjectResponsesScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final bool embedded;

  const CustomerProjectResponsesScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    this.embedded = false,
  });

  @override
  State<CustomerProjectResponsesScreen> createState() =>
      _CustomerProjectResponsesScreenState();
}

class _CustomerProjectResponsesScreenState
    extends State<CustomerProjectResponsesScreen> {
  List<MasterBid> _bids = [];
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
      _bids = MarketplaceLocalStore.instance.bidsForProject(widget.projectId);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final loading = const Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return ColoredBox(
          color: MarketplaceColors.backgroundFor(context),
          child: SafeArea(top: false, child: loading),
        );
      }
      return Scaffold(
        backgroundColor: MarketplaceColors.backgroundFor(context),
        appBar: AppBar(
          backgroundColor: MarketplaceColors.cardFor(context),
          foregroundColor: MarketplaceColors.textPrimaryFor(context),
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: MarketplaceColors.textPrimaryFor(context)),
          title: Text(
            'Отклики',
            style: TextStyle(
              fontFamily: AppTextStyle.fontFamily,
              fontWeight: FontWeight.w700,
              color: MarketplaceColors.textPrimaryFor(context),
            ),
          ),
        ),
        body: ColoredBox(
          color: MarketplaceColors.backgroundFor(context),
          child: SafeArea(child: loading),
        ),
      );
    }

    final bids = _bids;
    final textMuted = MarketplaceColors.textMutedFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    final inner = bids.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'На этот проект пока нет откликов. Опубликуйте заявку или подождите мастеров из ленты.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, height: 1.4),
              ),
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 28),
            itemCount: bids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = bids[i];
              return _BidTile(
                bid: b,
                projectTitle: widget.projectTitle,
              );
            },
          );

    if (widget.embedded) {
      return ColoredBox(
        color: MarketplaceColors.backgroundFor(context),
        child: SafeArea(top: false, child: inner),
      );
    }

    return Scaffold(
      backgroundColor: MarketplaceColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: MarketplaceColors.cardFor(context),
        foregroundColor: MarketplaceColors.textPrimaryFor(context),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: MarketplaceColors.textPrimaryFor(context)),
        title: Text(
          'Отклики · ${widget.projectTitle}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: MarketplaceColors.textPrimaryFor(context),
          ),
        ),
      ),
      body: ColoredBox(
        color: MarketplaceColors.backgroundFor(context),
        child: SafeArea(child: inner),
      ),
    );
  }
}

class _BidTile extends StatelessWidget {
  final MasterBid bid;
  final String projectTitle;

  const _BidTile({
    required this.bid,
    required this.projectTitle,
  });

  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        bid.masterName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bid.specialty,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: MarketplaceColors.gold, size: 20),
                    const SizedBox(width: 2),
                    Text(
                      bid.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: MarketplaceColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${bid.completedJobs} завершённых заказов',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  bid.priceOffer,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: MarketplaceColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  bid.durationOffer,
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              bid.message,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MasterPublicProfileScreen(
                          masterId: bid.masterId,
                          projectTitleForContract: projectTitle,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: MarketplaceColors.bluePrimary),
                  child: const Text('Профиль'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ContractConfirmScreen(
                          masterName: bid.masterName,
                          projectTitle: projectTitle,
                          priceOffer: bid.priceOffer,
                          durationOffer: bid.durationOffer,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: MarketplaceColors.ctaOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Выбрать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
