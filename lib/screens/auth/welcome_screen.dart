import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _didContinue = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Небольшая задержка чтобы экран успел появиться
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });

    // Переход только по кнопке, чтобы пользователь успел прочитать текст.
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continueToSurvey() async {
    if (_didContinue || !mounted) return;
    _didContinue = true;

    // Мягко растворяем экран перед переходом к опросу.
    await _ctrl.reverse();
    if (!mounted) return;

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Имя пользователя — берём первое слово чтобы не было длинно
    final fullName = auth.user?.username ?? '';
    final firstName = fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      const Spacer(flex: 2),

                      // Приветствие
                      AppText(
                        firstName.isNotEmpty
                            ? 'Рады видеть вас,\n$firstName!'
                            : 'Рады видеть вас!',
                        style: AppTextStyle.gropled(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.backgroundColor,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Подзаголовок
                      AppText(
                        'Пара вопросов — подстроим сценарий\nремонта и роль: заказчик или исполнитель.',
                        style: AppTextStyle.gropled(
                          fontSize: 18,
                          color: AppTheme.backgroundColor.withOpacity(0.65),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 2),

                      // Кнопка
                      GestureDetector(
                        onTap: _continueToSurvey,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: AppText(
                            'Продолжить →',
                            style: AppTextStyle.gropled(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}