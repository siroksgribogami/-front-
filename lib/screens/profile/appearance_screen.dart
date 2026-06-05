import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../providers/theme_provider.dart';

/// Экран настроек внешнего вида — тема + размер шрифта
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandScreen(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: BrandColors.canvas,
        foregroundColor: BrandColors.tar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: BrandAppBar(
            title: 'Внешний вид',
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      padding: EdgeInsets.zero,
      body: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'ТЕМА',
                  style: BrandUi.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.tar.withOpacity(0.4),
                  ).copyWith(letterSpacing: 0.6),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ThemePreviewCard(
                      name: 'Светлая',
                      selected: themeProv.themeMode == ThemeMode.light,
                      bg: BrandColors.milk,
                      fg: BrandColors.tar,
                      accent: BrandColors.needles,
                      onTap: () => themeProv.setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _ThemePreviewCard(
                      name: 'Тёмная',
                      selected: themeProv.themeMode == ThemeMode.dark,
                      bg: BrandColors.needlesDeep,
                      fg: BrandColors.milk,
                      accent: BrandColors.dawn,
                      onTap: () => themeProv.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _ThemePreviewCard(
                      name: 'Системная',
                      selected: themeProv.themeMode == ThemeMode.system,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.5, 0.5],
                        colors: [BrandColors.milk, BrandColors.needlesDeep],
                      ),
                      fg: BrandColors.tar.withOpacity(0.55),
                      accent: BrandColors.gilded,
                      onTap: () => themeProv.setThemeMode(ThemeMode.system),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 26, 4, 14),
                child: Text(
                  'МАСШТАБ ШРИФТА',
                  style: BrandUi.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.tar.withOpacity(0.4),
                  ).copyWith(letterSpacing: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: BrandColors.milk,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BrandColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'А',
                          style: BrandUi.inter(
                            fontSize: 13,
                            color: BrandColors.tar.withOpacity(0.55),
                          ),
                        ),
                        Text(
                          'Ремонт под ключ',
                          style: pochaevsk(
                            fontSize: 22 * themeProv.fontScale,
                            color: BrandColors.tar,
                          ),
                        ),
                        Text(
                          'А',
                          style: BrandUi.inter(
                            fontSize: 22,
                            color: BrandColors.tar.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: BrandColors.needles,
                        inactiveTrackColor: BrandColors.borderSubtle,
                        thumbColor: BrandColors.milk,
                        overlayColor: BrandColors.needles.withOpacity(0.1),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 11,
                          elevation: 2,
                        ),
                      ),
                      child: Slider(
                        value: themeProv.fontScale,
                        min: 0.7,
                        max: 1.2,
                        divisions: 10,
                        onChanged: (v) => themeProv.setFontScale(v),
                      ),
                    ),
                    Text(
                      themeProv.fontScaleLabel,
                      style: BrandUi.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: BrandColors.needles,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.name,
    required this.selected,
    required this.fg,
    required this.accent,
    required this.onTap,
    this.bg,
    this.gradient,
  });

  final String name;
  final bool selected;
  final Color? bg;
  final Gradient? gradient;
  final Color fg;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: bg,
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? BrandColors.clay : BrandColors.borderSubtle,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 8,
                        decoration: BoxDecoration(
                          color: fg.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 68,
                        height: 6,
                        decoration: BoxDecoration(
                          color: fg.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    width: 28,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: BrandColors.clay,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: BrandColors.onClay,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            name,
            style: BrandUi.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? BrandColors.tar
                  : BrandColors.tar.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
