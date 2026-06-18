import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:intl/intl.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';

/// Подтверждение выбора мастера и закрытие сделки.
/// При наличии [projectId] реально переводит проект в «В работе», меняет статус
/// откликов и создаёт чат с мастером (см. [MarketplaceLocalStore.selectMasterForProject]).
class ContractConfirmScreen extends StatelessWidget {
  final String masterName;
  final String projectTitle;

  /// Проект, по которому закрывается сделка. Без него экран просто фиксирует
  /// договорённость (запасной путь без контекста проекта).
  final String? projectId;
  final String? masterId;

  /// Конкретный отклик мастера (если выбор идёт из списка откликов).
  final MasterBid? bid;

  final String? priceOffer;
  final String? durationOffer;
  final double? rating;
  final String? specialty;

  const ContractConfirmScreen({
    super.key,
    required this.masterName,
    required this.projectTitle,
    this.projectId,
    this.masterId,
    this.bid,
    this.priceOffer,
    this.durationOffer,
    this.rating,
    this.specialty,
  });

  Future<void> _confirmDeal(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final store = MarketplaceLocalStore.instance;
    await store.ensureLoaded();

    if (projectId == null) {
      navigator.popUntil((r) => r.isFirst);
      messenger?.showSnackBar(
        SnackBar(content: Text('Договорённость с $masterName сохранена.')),
      );
      return;
    }

    // Находим отклик мастера: переданный, либо по masterId среди откликов проекта,
    // либо синтетический (если выбор шёл из профиля без отклика).
    MasterBid? resolved = bid;
    if (resolved == null) {
      for (final b in store.bidsForProject(projectId!)) {
        if (masterId != null && b.masterId == masterId) {
          resolved = b;
          break;
        }
      }
    }
    resolved ??= MasterBid(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      masterId: masterId ?? 'manual',
      masterName: masterName,
      specialty: specialty ?? '',
      rating: rating ?? 5.0,
      completedJobs: 0,
      priceOffer: priceOffer ?? '',
      durationOffer: durationOffer ?? '',
      message: '',
    );

    await store.selectMasterForProject(
      projectId: projectId!,
      bid: resolved,
      projectTitle: projectTitle,
    );

    navigator.popUntil((r) => r.isFirst);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '$masterName выбран. Проект «$projectTitle» в работе — чат открыт в «Сообщениях».',
        ),
      ),
    );
  }

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
                    color: BrandRuntime.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrandRuntime.border),
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
                                color: BrandRuntime.ink,
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
                                        color: BrandRuntime.ink.withOpacity(0.65),
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
                        decoration: BoxDecoration(
                          color: BrandRuntime.needlesFill,
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
                    color: BrandRuntime.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BrandRuntime.border),
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
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: BrandRuntime.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conditions[i].$1,
                                  style: BrandUi.inter(
                                    fontSize: 14,
                                    color: BrandRuntime.ink.withOpacity(0.65),
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
                            color: BrandRuntime.surface,
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
                                      'Итоговая стоимость',
                                      style: BrandUi.inter(
                                        fontSize: 12,
                                        color: BrandRuntime.needles,
                                      ),
                                    ),
                                    if (prepayLabel != null) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        prepayLabel,
                                        style: BrandUi.inter(
                                          fontSize: 11.5,
                                          color: BrandRuntime.ink.withOpacity(0.65),
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
                                  color: BrandRuntime.needles,
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
                      onPressed: () => _confirmDeal(context),
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
