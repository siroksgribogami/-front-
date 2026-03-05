import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../providers/theme_provider.dart';

/// Экран настроек внешнего вида — тема + размер шрифта
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSub = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textHint = isDark ? AppTheme.darkTextHint : AppTheme.textHint;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Внешний вид'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryColor,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Секция: Тема ──
              Text(
                'Тема',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyle.fontFamily,
                  color: textMain,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ThemeOption(
                      icon: Icons.light_mode_outlined,
                      label: 'Светлая',
                      isSelected: themeProv.themeMode == ThemeMode.light,
                      onTap: () => themeProv.setThemeMode(ThemeMode.light),
                      textMain: textMain,
                      textHint: textHint,
                    ),
                    Divider(height: 1, indent: 56, color: isDark ? AppTheme.darkBorder.withOpacity(0.4) : null),
                    _ThemeOption(
                      icon: Icons.dark_mode_outlined,
                      label: 'Тёмная',
                      isSelected: themeProv.themeMode == ThemeMode.dark,
                      onTap: () => themeProv.setThemeMode(ThemeMode.dark),
                      textMain: textMain,
                      textHint: textHint,
                    ),
                    Divider(height: 1, indent: 56, color: isDark ? AppTheme.darkBorder.withOpacity(0.4) : null),
                    _ThemeOption(
                      icon: Icons.brightness_auto_outlined,
                      label: 'Как в системе',
                      isSelected: themeProv.themeMode == ThemeMode.system,
                      onTap: () => themeProv.setThemeMode(ThemeMode.system),
                      textMain: textMain,
                      textHint: textHint,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Превью темы ──
              _ThemePreview(isDark: isDark),

              const SizedBox(height: 28),

              // ── Секция: Размер шрифта ──
              Text(
                'Размер шрифта',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyle.fontFamily,
                  color: textMain,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Превью текста
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заголовок',
                            style: TextStyle(
                              fontSize: 20 * themeProv.fontScale,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTextStyle.fontFamily,
                              color: textMain,
                              height: AppTextStyle.defaultHeight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Обычный текст выглядит так. Это предпросмотр с текущим масштабом шрифта.',
                            style: TextStyle(
                              fontSize: 14 * themeProv.fontScale,
                              color: textSub,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Мелкий текст · подпись',
                            style: TextStyle(
                              fontSize: 11 * themeProv.fontScale,
                              color: textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Слайдер
                    Row(
                      children: [
                        Text('A',
                            style: TextStyle(
                                fontSize: 12, color: textHint, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.15),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor: AppTheme.primaryColor.withOpacity(0.1),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            ),
                            child: Slider(
                              value: themeProv.fontScale,
                              min: 0.8,
                              max: 1.4,
                              divisions: 6,
                              onChanged: (v) => themeProv.setFontScale(v),
                            ),
                          ),
                        ),
                        Text('A',
                            style: TextStyle(
                                fontSize: 22, color: textHint, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(
                      themeProv.fontScaleLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
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

/// Вариант темы (радио)
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textMain;
  final Color textHint;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textMain,
    required this.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected ? AppTheme.primaryColor : textHint, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textMain,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22)
            else
              Icon(Icons.circle_outlined, color: textHint.withOpacity(0.4), size: 22),
          ],
        ),
      ),
    );
  }
}

/// Мини-превью текущей темы
class _ThemePreview extends StatelessWidget {
  final bool isDark;
  const _ThemePreview({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final card = isDark ? AppTheme.darkCard : Colors.white;
    final textM = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textS = isDark ? AppTheme.darkTextHint : AppTheme.textHint;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.accentColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Шапка
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            color: AppTheme.primaryColor,
            child: Column(
              children: [
                const Text(
                  'КРОВ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: AppTextStyle.fontFamily,
                    height: AppTextStyle.defaultHeight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'твой дом в порядке',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: AppTextStyle.fontFamily,
                    letterSpacing: 1.5,
                    height: AppTextStyle.defaultHeight,
                  ),
                ),
              ],
            ),
          ),
          // Тело
          Container(
            width: double.infinity,
            color: bg,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Карточка задачи
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Убрать кухню',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500, color: textM)),
                            Text('14:00 · Кухня',
                                style: TextStyle(fontSize: 10, color: textS)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Полить цветы',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500, color: textM)),
                            Text('утром · Гостиная',
                                style: TextStyle(fontSize: 10, color: textS)),
                          ],
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
    );
  }
}
