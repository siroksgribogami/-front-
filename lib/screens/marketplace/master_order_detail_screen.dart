import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_local_store.dart';
import 'before_after_viewer_screen.dart';

/// Карточка заказа из ленты: ТЗ, бюджет, адрес, отклик.
class MasterOrderDetailScreen extends StatefulWidget {
  final OrderFeedItem item;

  const MasterOrderDetailScreen({super.key, required this.item});

  @override
  State<MasterOrderDetailScreen> createState() => _MasterOrderDetailScreenState();
}

class _MasterOrderDetailScreenState extends State<MasterOrderDetailScreen> {
  OrderFeedItem get item => widget.item;

  Future<void> _showRespondSheet(BuildContext context) async {
    final priceCtrl = TextEditingController(text: '90 000 ₽');
    final daysCtrl = TextEditingController(text: '12 дней');
    final msgCtrl = TextEditingController(
      text: 'Здравствуйте! Готов подключиться на объекте в удобные даты.',
    );

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final pad = MediaQuery.viewInsetsOf(ctx).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: pad),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrandRuntime.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: BrandRuntime.border)),
                boxShadow: [
                  BoxShadow(
                    color: BrandRuntime.ink.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                    spreadRadius: -18,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ваш отклик',
                        style: pochaevsk(
                          fontSize: 18,
                          color: BrandRuntime.ink,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: _sheetField(ctx, 'Цена, ₽', priceCtrl),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _sheetField(ctx, 'Срок', daysCtrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      _sheetField(ctx, 'Сообщение', msgCtrl, maxLines: 3),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                          final priceOffer = priceCtrl.text.trim();
                          final durationOffer = daysCtrl.text.trim();
                          final message = msgCtrl.text.trim();
                          Navigator.of(ctx).pop();

                          final messenger = ScaffoldMessenger.maybeOf(context);
                          final auth = context.read<AuthProvider>();
                          final user = auth.user;
                          final masterName = user?.visibleName.trim().isNotEmpty == true
                              ? user!.visibleName
                              : 'Исполнитель';

                          await MarketplaceLocalStore.instance.ensureLoaded();
                          await MarketplaceLocalStore.instance.submitMasterBid(
                            orderId: item.id,
                            bid: MasterBid(
                              id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
                              masterId: user?.id.toString() ?? 'local',
                              masterName: masterName,
                              specialty: 'По заявке из ленты',
                              rating: 5.0,
                              completedJobs: 0,
                              priceOffer: priceOffer,
                              durationOffer: durationOffer,
                              message: message,
                            ),
                            projectTitleForMyBids: item.workType,
                          );

                          if (!context.mounted) return;
                          messenger?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Отклик сохранён. Заказчик увидит его в списке откликов на проект.',
                              ),
                            ),
                          );
                        },
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandColors.clay,
                            foregroundColor: BrandColors.onClay,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BrandUi.buttonRadius,
                            ),
                            textStyle: BrandUi.inter(fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Отправить отклик'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      priceCtrl.dispose();
      daysCtrl.dispose();
      msgCtrl.dispose();
    }
  }

  Widget _sheetField(
    BuildContext context,
    String label,
    TextEditingController c, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BrandUi.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.ink.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: BrandUi.inter(fontSize: 15),
          decoration: BrandUi.inputDecoration(),
        ),
      ],
    );
  }

  String get _subtitle {
    final district = item.district.replaceAll('Москва, ', '');
    return '${item.workType} · $district';
  }

  List<String> get _specChips {
    final chips = <String>[item.workType];
    if (item.has3d) chips.add('3D-визуализация');
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final bidsCount =
        MarketplaceLocalStore.instance.bidsForProject(item.id).length;

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: BrandAppBar(
                title: 'Заказ',
                subtitle: _subtitle,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(BrandUi.pad, 0, BrandUi.pad, 16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: BrandRuntime.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: BrandStripedPlaceholder(
                        label: 'фото объекта · ${item.workType.toLowerCase()}',
                        height: 130,
                        radius: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      const Expanded(
                        child: _DetailStatTile(
                          label: 'Площадь',
                          value: '—',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailStatTile(
                          label: 'Бюджет',
                          value: item.budgetLabel,
                          accent: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: _DetailStatTile(
                          label: 'Срок',
                          value: 'По ТЗ',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  BrandCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandKicker('Техзадание'),
                        const SizedBox(height: 9),
                        Text(
                          item.fullSpec,
                          style: BrandUi.inter(
                            fontSize: 13.5,
                            color: BrandRuntime.ink.withOpacity(0.65),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _specChips
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandRuntime.card,
                                    borderRadius: BrandUi.chipRadius,
                                    border: Border.all(
                                      color: BrandRuntime.borderStrong,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    c,
                                    style: BrandUi.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      const BrandAvatar(name: 'Заказчик', size: 40, radius: 12),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Заказчик',
                              style: BrandUi.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.district,
                              style: BrandUi.inter(
                                fontSize: 12,
                                color: BrandRuntime.ink.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$bidsCount ОТКЛИКОВ'.toUpperCase(),
                        style: BrandUi.monoLabel(
                          fontSize: 10,
                          color: BrandRuntime.ink.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                  if (item.has3d) ...[
                    const SizedBox(height: 16),
                    BrandGhostButton(
                      label: 'Смотреть визуализацию',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BeforeAfterViewerScreen(
                              title: '${item.workType} · визуализация',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: BrandRuntime.card,
                border: Border(top: BorderSide(color: BrandRuntime.border)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: BrandRuntime.ink.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                    spreadRadius: -18,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: FilledButton(
                  onPressed: () => _showRespondSheet(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.clay,
                    foregroundColor: BrandColors.onClay,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BrandUi.buttonRadius,
                    ),
                    textStyle: BrandUi.inter(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Откликнуться'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatTile extends StatelessWidget {
  const _DetailStatTile({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: BrandRuntime.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: BrandUi.inter(
              fontSize: 10.5,
              color: BrandRuntime.ink.withOpacity(0.35),
            ).copyWith(letterSpacing: 0.4),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: pochaevsk(
              fontSize: 17,
              color: accent ? BrandRuntime.needles : BrandRuntime.needles,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
