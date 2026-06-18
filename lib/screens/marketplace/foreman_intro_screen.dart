import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_runtime.dart';
import '../../core/theme/brand_ui.dart';
import 'ai_foreman_chat_tab.dart';

/// Приветственная страница ИИ-прораба — «зачем ИИ» за 2 секунды.
///
/// Закрывает претензию: непонятно, зачем нужен искусственный интеллект.
/// Одна понятная мысль + один главный CTA «Собрать проект с ИИ-прорабом».
/// По нажатию открывается чат с прорабом (быстрый диалог по шагам).
class ForemanIntroScreen extends StatelessWidget {
  const ForemanIntroScreen({super.key, this.projectId});

  /// Если открыли из конкретного проекта — пробрасываем в чат.
  final int? projectId;

  static Future<void> open(BuildContext context, {int? projectId}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForemanIntroScreen(projectId: projectId),
      ),
    );
  }

  void _startChat(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: BrandRuntime.canvas,
          body: SafeArea(
            child: AiForemanChatTab(
              showHeader: true,
              projectId: projectId,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BrandBackButton(onPressed: () => Navigator.of(context).maybePop()),
                  ),
                  const Spacer(flex: 2),

                  // Герой: аватар прораба + крупный заголовок
                  const ForemanAvatar(size: 84, radius: 24),
                  const SizedBox(height: 20),
                  Text(
                    'ИИ-прораб соберёт\nваш проект за пару минут',
                    textAlign: TextAlign.center,
                    style: pochaevsk(
                      fontSize: 26,
                      height: 1.12,
                      color: BrandRuntime.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Коротко спросит, что нужно — и сам соберёт ТЗ, '
                    'смету и карточку для биржи мастеров.',
                    textAlign: TextAlign.center,
                    style: BrandUi.inter(
                      fontSize: 15,
                      height: 1.45,
                      color: BrandRuntime.ink.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Зачем нужен ИИ — три ценности (Диана)
                  const _ValueRow(
                    icon: Icons.description_outlined,
                    title: 'Соберёт качественное ТЗ',
                    subtitle: 'Опишет объём работ так, чтобы мастера поняли задачу',
                  ),
                  const SizedBox(height: 14),
                  const _ValueRow(
                    icon: Icons.forum_outlined,
                    title: 'Подскажет и посоветует',
                    subtitle: 'Что нужно для ремонта и как выбрать хорошего мастера',
                  ),
                  const SizedBox(height: 14),
                  const _ValueRow(
                    icon: Icons.storefront_outlined,
                    title: 'Сделает карточку проекта',
                    subtitle: 'Готовое объявление для биржи мастеров',
                  ),

                  const Spacer(flex: 3),

                  // Один главный CTA
                  SizedBox(
                    width: double.infinity,
                    child: BrandPrimaryButton(
                      label: 'Собрать проект с ИИ-прорабом',
                      onPressed: () => _startChat(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Бесплатно • Около 2 минут',
                    style: BrandUi.inter(
                      fontSize: 12.5,
                      color: BrandRuntime.ink.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BrandColors.needlesLight.withOpacity(0.30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: BrandColors.needlesDark),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: BrandUi.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: BrandRuntime.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: BrandUi.inter(
                  fontSize: 13,
                  height: 1.35,
                  color: BrandRuntime.ink.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
