import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';

/// Полноэкранное портфолио мастера (заглушки до подключения медиа с сервера).
class MasterPortfolioScreen extends StatelessWidget {
  const MasterPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final border = MarketplaceColors.textMutedFor(context).withOpacity(0.2);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Портфолио',
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: MarketplaceColors.textPrimaryFor(context),
          ),
        ),
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: MarketplaceColors.textPrimaryFor(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          MarketplaceColors.horizontalPaddingFor(context),
          8,
          MarketplaceColors.horizontalPaddingFor(context),
          24,
        ),
        children: [
          Text(
            'Здесь будут фото работ. Сейчас — демо-сетка.',
            style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(
              12,
              (i) => Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
