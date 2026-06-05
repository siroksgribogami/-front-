import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/brand_solid_background.dart';
import '../../core/theme/brand_ui.dart';
import '../../providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onContinue,
    this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback? onSkip;

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

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continueToSurvey() async {
    if (_didContinue || !mounted) return;
    _didContinue = true;
    await _ctrl.reverse();
    if (!mounted) return;
    widget.onContinue();
  }

  Future<void> _skip() async {
    if (_didContinue || !mounted) return;
    _didContinue = true;
    await _ctrl.reverse();
    if (!mounted) return;
    (widget.onSkip ?? widget.onContinue)();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fullName = auth.user?.username ?? '';
    final firstName = fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: BrandSolidBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 36, 32, 44),
                child: Column(
                  children: [
                    const Spacer(),
                    const BrandCrest(size: 9),
                    const SizedBox(height: 30),
                    const BrandKicker('Аккаунт создан', onDark: true, fontSize: 10.5),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: pochaevsk(
                          fontSize: 52,
                          color: BrandColors.onNeedles,
                          height: 0.98,
                        ),
                        children: [
                          const TextSpan(text: 'Добро\nпожаловать,\n'),
                          TextSpan(
                            text: firstName.isNotEmpty ? firstName : 'друг',
                            style: pochaevsk(
                              fontSize: 52,
                              color: BrandColors.dawn,
                              height: 0.98,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const SizedBox(
                      width: 130,
                      child: BrandLineDivider(margin: EdgeInsets.zero),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Ответьте на пару вопросов — и мы соберём ленту мастеров и подсказок под ваш ремонт.',
                      textAlign: TextAlign.center,
                      style: BrandUi.inter(
                        fontSize: 15,
                        height: 1.55,
                        color: BrandColors.onNeedles.withOpacity(0.82),
                      ),
                    ),
                    const Spacer(flex: 2),
                    BrandAccentButton(
                      label: 'Пройти опрос · 1 минута',
                      onPressed: _continueToSurvey,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Пропустить и войти',
                        style: BrandUi.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: BrandColors.onNeedles.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
