import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../providers/auth_provider.dart';

/// Экран после регистрации: пользователь подтверждает email по ссылке из письма.
///
/// Отправка письма и проверка токена выполняются на бэкенде; здесь только UX и вызовы API.
class EmailVerificationScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const EmailVerificationScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _busy = false;
  String? _banner;

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _banner = null;
    });
    final err = await context.read<AuthProvider>().resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err == null) {
        _banner = 'Если адрес верный, письмо будет отправлено в течение нескольких минут.';
      } else {
        _banner = err;
      }
    });
  }

  Future<void> _checkAndContinue() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _banner = null;
    });
    final auth = context.read<AuthProvider>();
    final verified = await auth.refreshVerificationFromServer();
    if (!mounted) return;
    setState(() => _busy = false);

    if (verified) {
      widget.onContinue();
      return;
    }

    setState(() {
      _banner =
          'Почта пока не подтверждена. Откройте письмо и перейдите по ссылке, затем нажмите «Проверить снова».';
    });
  }

  void _skipForNow() {
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 48, 30, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: BrandRuntime.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: BrandRuntime.border),
                      ),
                      child: const Stack(
                        fit: StackFit.expand,
                        children: [
                          BrandCornerTicks(inset: 10, size: 14),
                          Center(
                            child: Icon(
                              Icons.mail_outline_rounded,
                              size: 44,
                              color: BrandColors.clay,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: BrandRuntime.needlesFill,
                          shape: BoxShape.circle,
                          border: Border.all(color: BrandRuntime.canvas, width: 3),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: BrandColors.onNeedles,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const BrandKicker('Почти готово', fontSize: 10.5),
              const SizedBox(height: 12),
              Text(
                'Подтвердите почту',
                textAlign: TextAlign.center,
                style: pochaevsk(
                  fontSize: 32,
                  color: BrandRuntime.ink,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: BrandUi.inter(
                    fontSize: 15,
                    height: 1.55,
                    color: BrandRuntime.ink.withOpacity(0.55),
                  ),
                  children: [
                    const TextSpan(
                      text: 'Мы отправили письмо на ',
                    ),
                    TextSpan(
                      text: email.isEmpty ? 'ваш email' : email,
                      style: BrandUi.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrandRuntime.ink,
                      ),
                    ),
                    const TextSpan(
                      text: '. Перейдите по ссылке, чтобы активировать аккаунт.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: BrandRuntime.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: BrandRuntime.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: BrandColors.gilded,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Письмо придёт в течение 2 минут',
                      style: BrandUi.inter(
                        fontSize: 13,
                        color: BrandRuntime.ink.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (_banner != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BrandColors.sandstone.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BrandRuntime.border),
                  ),
                  child: Text(
                    _banner!,
                    style: BrandUi.inter(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              BrandPrimaryButton(
                label: _busy ? 'Проверяем…' : 'Продолжить',
                onPressed: _busy ? null : _checkAndContinue,
              ),
              const SizedBox(height: 12),
              BrandGhostButton(
                label: _busy ? 'Отправляем…' : 'Отправить снова',
                onPressed: _busy ? null : _resend,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy ? null : _skipForNow,
                child: Text(
                  'Продолжить без проверки',
                  style: BrandUi.inter(
                    fontSize: 13,
                    color: BrandRuntime.ink.withOpacity(0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
