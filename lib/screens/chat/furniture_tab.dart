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
                childAspectRatio: 0.72,
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
            height: 120,
            decoration: BoxDecoration(
              color: MarketplaceColors.bluePrimary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(categoryIcon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    item.category,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _formatPrice(item.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MarketplaceColors.bluePrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: MarketplaceColors.gold),
                    const SizedBox(width: 2),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.region,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildSpecChip(context, Icons.straighten, item.dimensions),
                    _buildSpecChip(context, Icons.category_outlined, item.material),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Цвета: ',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Expanded(
                      child: Text(
                        item.colors.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('На плане'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MarketplaceColors.bluePrimary,
                          side: BorderSide(color: MarketplaceColors.bluePrimary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Добавлено в корзину: ${item.name}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: const Text('Купить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MarketplaceColors.ctaOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
