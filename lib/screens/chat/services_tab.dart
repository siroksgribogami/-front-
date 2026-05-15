import 'package:flutter/material.dart';

import '../../core/theme/marketplace_colors.dart';
import '../../models/services_furniture.dart';

/// Вкладка «Услуги» (не ИИ): синий бренд, золото у рейтинга — по гайду.
class ServicesTab extends StatelessWidget {
  final List<ServiceCompany>? items;

  const ServicesTab({
    super.key,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return ColoredBox(
      color: bg,
      child: (items ?? catalogServices).isEmpty
          ? Center(
              child: Text(
                'Ничего не найдено по фильтрам',
                style: TextStyle(color: textMuted),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                MarketplaceColors.horizontalPaddingFor(context),
                12,
                MarketplaceColors.horizontalPaddingFor(context),
                16,
              ),
              itemCount: (items ?? catalogServices).length,
              itemBuilder: (context, index) {
                return _buildServiceCard(context, (items ?? catalogServices)[index]);
              },
            ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceCompany service) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final shadow = Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.12;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MarketplaceColors.textMutedFor(context).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadow),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: MarketplaceColors.bluePrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(service.icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MarketplaceColors.bluePrimary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: MarketplaceColors.bluePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: MarketplaceColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        service.rating.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${service.reviewsCount} отзывов',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service.priceRange,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MarketplaceColors.bluePrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Звоним: ${service.phone}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Позвонить'),
                style: TextButton.styleFrom(
                  foregroundColor: MarketplaceColors.bluePrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
