import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';

/// Подтверждение выбора мастера и создание договора (локально в приложении).
class ContractConfirmScreen extends StatelessWidget {
  final String masterName;
  final String projectTitle;
  final String? priceOffer;
  final String? durationOffer;
  final double? rating;
  final String? specialty;

  const ContractConfirmScreen({
    super.key,
    required this.masterName,
    required this.projectTitle,
    this.priceOffer,
    this.durationOffer,
    this.rating,
    this.specialty,
  });

  int? _parsePriceRub(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final total = _parsePriceRub(priceOffer);
    final prepay = total != null ? (total * 0.3).round() : null;
    final prepayLabel = prepay != null
        ? 'Предоплата 30% · ${NumberFormat('#,###', 'ru').format(prepay).replaceAll(',', ' ')} ₽'
        : null;
    final startDate = DateFormat('d MMMM yyyy', 'ru').format(
      DateTime.now().add(const Duration(days: 14)),
    );

    final conditions = <(String, String)>[
      ('Объект', projectTitle),
      ('Адрес', 'Уточняется при замере'),
      ('Состав', 'Под ключ с материалами'),
      ('Старт', startDate),
      if (durationOffer != null) ('Срок', durationOffer!),
    ];

    return BrandScreen(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandAppBar(
            title: 'Договорённость',
            subtitle: 'Финальное подтверждение',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BrandColors.milk,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrandColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      BrandAvatar(
                        name: masterName,
                        size: 52,
                        radius: 15,
                        tone: BrandAvatarTone.clay,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              masterName,
                              style: pochaevsk(
                                fontSize: 18,
                                color: BrandColors.tar,
                                height: 1,
                              ),
                            ),
                            if (rating != null || specialty != null) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  if (rating != null) ...[
                                    _StarRating(value: rating!, size: 11),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      [
                                        if (rating != null)
                                          rating!.toStringAsFixed(1),
                                        if (specialty != null) specialty!,
                                      ].join(' · '),
                                      style: BrandUi.inter(
                                        fontSize: 12.5,
                                        color: BrandColors.tar.withOpacity(0.65),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: BrandColors.needles,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: BrandColors.onNeedles,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: BrandColors.milk,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BrandColors.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: BrandKicker('Условия работ'),
                      ),
                      for (var i = 0; i < conditions.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: BrandColors.borderSubtle),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conditions[i].$1,
                                  style: BrandUi.inter(
                                    fontSize: 14,
                                    color: BrandColors.tar.withOpacity(0.65),
                                  ),
                                ),
                              ),
                              Text(
                                conditions[i].$2,
                                style: BrandUi.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (priceOffer != null)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                          decoration: BoxDecoration(
                            color: BrandColors.linen,
                            border: const Border(
                              top: BorderSide(color: BrandColors.borderSubtle),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Итоговая стоимость',
                                      style: BrandUi.inter(
                                        fontSize: 12,
                                        color: BrandColors.needles,
                                      ),
                                    ),
                                    if (prepayLabel != null) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        prepayLabel,
                                        style: BrandUi.inter(
                                          fontSize: 11.5,
                                          color: BrandColors.tar.withOpacity(0.65),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                priceOffer!,
                                style: pochaevsk(
                                  fontSize: 28,
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: BrandColors.sandstone,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: BrandColors.surik,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Оплата проходит через сервис и резервируется до приёмки работ.',
                          style: BrandUi.inter(
                            fontSize: 12.5,
                            color: BrandColors.surik,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            child: Row(
              children: [
                BrandGhostButton(
                  label: 'Изменить',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: BrandAccentButton(
                      label: 'Подтвердить и оплатить',
                      onPressed: () {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      messenger?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Договор с $masterName сохранён в приложении. Сервер подключится позже.',
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
