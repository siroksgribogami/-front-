import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';

/// Подтверждение выбора мастера и создание договора (локально в приложении).
class ContractConfirmScreen extends StatelessWidget {
  final String masterName;
  final String projectTitle;
  final String? priceOffer;
  final String? durationOffer;

  const ContractConfirmScreen({
    super.key,
    required this.masterName,
    required this.projectTitle,
    this.priceOffer,
    this.durationOffer,
  });

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Договор',
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 24),
          children: [
            Text(
              'Вы выбрали исполнителя',
              style: TextStyle(
                fontFamily: AppTextStyle.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              projectTitle,
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: MarketplaceColors.textMutedFor(context).withOpacity(0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    masterName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  if (priceOffer != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Согласованная сумма: $priceOffer',
                      style: const TextStyle(
                        fontSize: 15,
                        color: MarketplaceColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (durationOffer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Сроки: $durationOffer',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Дальнейшее оформление и оплата появятся после подключения бэкенда. Сейчас это демонстрация UX.',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.maybeOf(context);
                Navigator.of(context).popUntil((r) => r.isFirst);
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text('Договор с $masterName сохранён в приложении. Сервер подключится позже.'),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: MarketplaceColors.ctaOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Подтвердить и создать договор'),
            ),
          ],
        ),
      ),
    );
  }
}
