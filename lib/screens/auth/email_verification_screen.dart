import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
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
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: Colors.white.withOpacity(0.95),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Подтвердите email',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: AppTextStyle.fontFamily,
                      height: AppTextStyle.defaultHeight,
                      leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Мы отправили письмо со ссылкой для подтверждения на адрес:',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      email.isEmpty ? '—' : email,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Не получили письмо? Проверьте папку «Спам». Ниже можно запросить отправку ещё раз.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                  if (_banner != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _banner!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: _busy ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.55)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTextStyle.fontFamily,
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Отправить письмо ещё раз'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : _checkAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTextStyle.fontFamily,
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                      ),
                    ),
                    child: const Text('Я подтвердил — продолжить'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : _skipForNow,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.85),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTextStyle.fontFamily,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.5),
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                      ),
                    ),
                    child: const Text('Продолжить без проверки'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Когда на сервере включат обязательное подтверждение, вход без верификации может быть ограничен.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white.withOpacity(0.5),
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
