import 'package:flutter/material.dart';

import '../../core/theme/marketplace_colors.dart';
import '../../models/services_furniture.dart';

/// Вкладка «Мебель»: вторичное действие — синий контур, единственная CTA на карточке — оранжевая.
class FurnitureTab extends StatelessWidget {
  final VoidCallback? onViewOnMap;
  final List<FurnitureItem>? items;

  const FurnitureTab({
    super.key,
    this.onViewOnMap,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return ColoredBox(
      color: bg,
      child: (items ?? catalogFurniture).isEmpty
          ? Center(
              child: Text(
                'Ничего не найдено по фильтрам',
                style: TextStyle(color: textMuted),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.fromLTRB(
                MarketplaceColors.horizontalPaddingFor(context),
                12,
                MarketplaceColors.horizontalPaddingFor(context),
                16,
              ),
              itemCount: (items ?? catalogFurniture).length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // Высота карточки фиксирована: контент компактный, ничего не вылезает.
                mainAxisExtent: 320,
              ),
              itemBuilder: (context, index) =>
                  _buildFurnitureCard(context, (items ?? catalogFurniture)[index]),
            ),
    );
  }

  Widget _buildFurnitureCard(BuildContext context, FurnitureItem item) {
    String categoryIcon = '🪑';
    switch (item.category) {
      case 'Гостиная':
        categoryIcon = '🛋️';
        break;
      case 'Кухня':
        categoryIcon = '🍽️';
        break;
      case 'Спальня':
        categoryIcon = '🛏️';
        break;
      case 'Кабинет':
        categoryIcon = '🖥️';
        break;
    }

    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final shadow = Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.08;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textMuted.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadow),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: MarketplaceColors.bluePrimary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Center(
              child: Text(categoryIcon, style: const TextStyle(fontSize: 40)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(item.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: MarketplaceColors.bluePrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: MarketplaceColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.region,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSpecChip(context, Icons.straighten, item.dimensions),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (onViewOnMap != null) {
                              onViewOnMap!();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Переход на карту...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MarketplaceColors.bluePrimary,
                            side: BorderSide(
                              color:
                                  MarketplaceColors.bluePrimary.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size.fromHeight(36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'На плане',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Добавлено в корзину: ${item.name}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MarketplaceColors.ctaOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size.fromHeight(36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Купить',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(BuildContext context, IconData icon, String text) {
    final c = MarketplaceColors.textMutedFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: c),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final priceInt = price.toInt();
    final formatted = priceInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
    return '$formatted ₽';
  }
}
