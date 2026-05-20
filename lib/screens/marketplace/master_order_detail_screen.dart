import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
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
      backgroundColor: MarketplaceColors.cardFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final pad = MediaQuery.viewInsetsOf(ctx).bottom;
        final textPrimary = MarketplaceColors.textPrimaryFor(ctx);
        final textMuted = MarketplaceColors.textMutedFor(ctx);
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: pad + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Предложение по заказу',
                  style: TextStyle(
                    fontFamily: AppTextStyle.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _sheetField(ctx, 'Сумма', priceCtrl),
                const SizedBox(height: 10),
                _sheetField(ctx, 'Срок', daysCtrl),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Сообщение заказчику',
                    labelStyle: TextStyle(color: textMuted),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
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
                    backgroundColor: MarketplaceColors.bluePrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Отправить предложение'),
                ),
              ],
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

  Widget _sheetField(BuildContext context, String label, TextEditingController c) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    return TextField(
      controller: c,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Заказ',
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 28),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MarketplaceColors.bluePrimary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.workType,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: MarketplaceColors.bluePrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.budgetLabel,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 18, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.district,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.addressShort,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Техническое задание',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.fullSpec,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: textSecondary,
              ),
            ),
            if (item.has3d) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BeforeAfterViewerScreen(
                        title: '${item.workType} · визуализация',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: MarketplaceColors.bluePrimary,
                  side: BorderSide(color: MarketplaceColors.bluePrimary.withOpacity(0.5)),
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.view_in_ar_rounded, size: 20),
                label: const Text('Смотреть визуализацию (До/После)'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _showRespondSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: MarketplaceColors.ctaOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Откликнуться'),
            ),
          ],
        ),
      ),
    );
  }
}
