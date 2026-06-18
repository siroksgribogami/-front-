import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
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

  String? _bestBidId(List<MasterBid> bids) {
    if (bids.isEmpty) return null;
    MasterBid? best;
    for (final b in bids) {
      if (best == null || b.rating > best.rating) best = b;
    }
    return best?.id;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final loading = const Center(child: CircularProgressIndicator());
      if (widget.embedded) {
        return ColoredBox(
          color: BrandRuntime.canvas,
          child: SafeArea(top: false, child: loading),
        );
      }
      return Scaffold(
        backgroundColor: BrandRuntime.canvas,
        body: SafeArea(child: loading),
      );
    }

    final bids = _bids;
    final bestId = _bestBidId(bids);
    final hasSelected = bids.any((b) => b.isSelected);
    final subtitle = widget.projectTitle;

    final inner = bids.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'На этот проект пока нет откликов. Опубликуйте заявку или подождите мастеров из ленты.',
                textAlign: TextAlign.center,
                style: BrandUi.inter(
                  color: BrandRuntime.ink.withOpacity(0.55),
                  height: 1.4,
                ),
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            itemCount: bids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = bids[i];
              return _BidTile(
                bid: b,
                projectId: widget.projectId,
                projectTitle: widget.projectTitle,
                isBest: b.id == bestId && !hasSelected,
                dealClosed: hasSelected,
                index: i,
              );
            },
          );

    final body = ColoredBox(
      color: BrandRuntime.canvas,
      child: SafeArea(
        top: !widget.embedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandAppBar(
              title: 'Отклики',
              subtitle: subtitle,
              onBack: widget.embedded
                  ? null
                  : () => Navigator.of(context).maybePop(),
              actions: BrandStatus(
                label: '${bids.length} откликов',
                kind: BrandStatusKind.market,
              ),
            ),
            Expanded(child: inner),
          ],
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: body,
    );
  }
}

class _BidTile extends StatelessWidget {
  final MasterBid bid;
  final String projectId;
  final String projectTitle;
  final bool isBest;

  /// По проекту уже выбран мастер — остальные отклики блокируются.
  final bool dealClosed;
  final int index;

  const _BidTile({
    required this.bid,
    required this.projectId,
    required this.projectTitle,
    required this.isBest,
    required this.dealClosed,
    required this.index,
  });

  BrandAvatarTone get _tone {
    const tones = BrandAvatarTone.values;
    return tones[index % tones.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBest ? BrandRuntime.needles : BrandRuntime.border,
          width: isBest ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: BrandRuntime.needles,
              child: Row(
                children: [
                  Icon(Icons.star_rounded, size: 13, color: BrandColors.dawn),
                  const SizedBox(width: 7),
                  Text(
                    'РЕКОМЕНДАЦИЯ ПРОРАБА · ЛУЧШАЯ ЦЕНА/РЕЙТИНГ',
                    style: BrandUi.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.onNeedles,
                    ).copyWith(letterSpacing: 0.03 * 16),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandAvatar(
                      name: bid.masterName,
                      size: 46,
                      radius: 13,
                      tone: _tone,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bid.masterName,
                            style: pochaevsk(
                              fontSize: 17,
                              color: BrandRuntime.ink,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _StarRating(value: bid.rating, size: 11),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${bid.rating.toStringAsFixed(1)} · ${bid.completedJobs} · ${bid.specialty}',
                                  style: BrandUi.inter(
                                    fontSize: 12.5,
                                    color: BrandRuntime.ink.withOpacity(0.65),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  bid.message,
                  style: BrandUi.inter(
                    fontSize: 13.5,
                    color: BrandRuntime.ink.withOpacity(0.65),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: BrandRuntime.border),
                      bottom: BorderSide(color: BrandRuntime.border),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ЦЕНА',
                                style: BrandUi.inter(
                                  fontSize: 11,
                                  color: BrandRuntime.ink.withOpacity(0.45),
                                ).copyWith(letterSpacing: 0.04 * 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bid.priceOffer,
                                style: pochaevsk(
                                  fontSize: 22,
                                  color: BrandRuntime.needles,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          color: BrandRuntime.border,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'СРОК',
                                  style: BrandUi.inter(
                                    fontSize: 11,
                                    color: BrandRuntime.ink.withOpacity(0.45),
                                  ).copyWith(letterSpacing: 0.04 * 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bid.durationOffer,
                                  style: pochaevsk(
                                    fontSize: 22,
                                    color: BrandRuntime.ink,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    BrandGhostButton(
                      label: 'Профиль',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MasterPublicProfileScreen(
                              masterId: bid.masterId,
                              projectId: projectId,
                              projectTitleForContract: projectTitle,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _actionForStatus(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionForStatus(BuildContext context) {
    if (bid.isSelected) {
      return Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandRuntime.needlesFill,
          borderRadius: BrandUi.buttonRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 18, color: BrandRuntime.needles),
            const SizedBox(width: 7),
            Text(
              'Выбран · в работе',
              style: BrandUi.inter(
                fontWeight: FontWeight.w600,
                color: BrandRuntime.needles,
              ),
            ),
          ],
        ),
      );
    }
    if (dealClosed) {
      return const BrandGhostButton(label: 'Не выбран', onPressed: null);
    }
    return isBest
        ? SizedBox(
            width: double.infinity,
            child: BrandAccentButton(
              label: 'Выбрать мастера',
              onPressed: () => _chooseMaster(context),
            ),
          )
        : BrandPrimaryButton(
            label: 'Выбрать мастера',
            onPressed: () => _chooseMaster(context),
          );
  }

  void _chooseMaster(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContractConfirmScreen(
          masterName: bid.masterName,
          projectId: projectId,
          masterId: bid.masterId,
          bid: bid,
          projectTitle: projectTitle,
          priceOffer: bid.priceOffer,
          durationOffer: bid.durationOffer,
          rating: bid.rating,
          specialty: bid.specialty,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, this.size = 12});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = value >= i + 1 || (value > i && value < i + 1);
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: BrandColors.gilded,
        );
      }),
    );
  }
}
