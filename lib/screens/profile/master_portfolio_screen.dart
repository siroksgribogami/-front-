import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';

/// Полноэкранное портфолио мастера (заглушки до подключения медиа с сервера).
class MasterPortfolioScreen extends StatelessWidget {
  const MasterPortfolioScreen({
    super.key,
    this.masterName = 'Мастер',
    this.worksCount = 28,
  });

  final String masterName;
  final int worksCount;

  static const _gridItems = [
    ('Санузел гостевой', 'санузел'),
    ('Кухонный фартук', 'фартук'),
    ('Душевая ниша', 'душевая'),
    ('Тёплый пол', 'пол'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.needlesDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  BrandBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                    onDark: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Портфолио',
                          style: pochaevsk(
                            fontSize: 19,
                            color: BrandColors.onNeedles,
                          ),
                        ),
                        Text(
                          '$masterName · $worksCount работ',
                          style: BrandUi.inter(
                            fontSize: 12.5,
                            color: BrandColors.onNeedles.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BrandUi.pad),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    const BrandStripedPlaceholder(
                      label: 'ванная под ключ · мрамор',
                      height: 230,
                      radius: 0,
                      dark: true,
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ванная «Мрамор»',
                                  style: pochaevsk(
                                    fontSize: 20,
                                    color: BrandColors.onNeedles,
                                  ),
                                ),
                                Text(
                                  'ХАМОВНИКИ · 8 М² · 2025',
                                  style: BrandUi.monoLabel(
                                    fontSize: 10,
                                    color: BrandColors.onNeedles.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.tar.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.view_in_ar_rounded,
                                  size: 14,
                                  color: BrandColors.onNeedles,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '3D-тур',
                                  style: BrandUi.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: BrandColors.onNeedles,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(BrandUi.pad, 0, BrandUi.pad, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemCount: _gridItems.length,
                itemBuilder: (_, i) {
                  final (title, label) = _gridItems[i];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            BrandStripedPlaceholder(
                              label: label,
                              height: constraints.maxHeight,
                              radius: 0,
                              dark: true,
                            ),
                            Positioned(
                              left: 10,
                              bottom: 9,
                              child: Text(
                                title,
                                style: BrandUi.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: BrandColors.onNeedles,
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
