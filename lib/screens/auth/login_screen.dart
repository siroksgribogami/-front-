import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../config/app_theme.dart';
import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/brand_solid_background.dart';
import '../../core/theme/brand_ui.dart';
import '../../utils/register_contact_validation.dart';
import '../../utils/user_contact_display.dart';
import 'widgets/brand_frame_splash.dart';

/// Экран входа — сплошной бренд-зелёный #325D3C, рамка с логотипом.
class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onRegisterTap,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showForm = false;

  late final AnimationController _transitionCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOutCubic));
    _transitionCtrl.forward();
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _closeForm() {
    if (!mounted) return;
    setState(() => _showForm = false);
  }

  void _afterFrameExitOpenLogin() {
    if (!mounted) return;
    setState(() => _showForm = true);
  }

  void _afterFrameExitOpenRegister() {
    if (!mounted) return;
    widget.onRegisterTap?.call();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final contact = _emailController.text.trim();
    final loginEmail = contact.contains('@')
        ? contact
        : UserContactDisplay.resolveLoginEmail(contact);

    final success = await authProvider.login(
      email: loginEmail,
      password: _passwordController.text,
    );

    if (success && mounted) {
      await context.read<RoleProvider>().load();
      widget.onLoginSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _showForm ? _buildLoginForm() : _buildWelcomeScreen(),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: BrandSolidBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: BrandFrameSplash(
                key: ValueKey('brand_frame_$_showForm'),
                onLogin: _afterFrameExitOpenLogin,
                onRegister: widget.onRegisterTap == null
                    ? null
                    : _afterFrameExitOpenRegister,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: BrandSolidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BrandBackButton(onPressed: _closeForm, onDark: true),
                  ),
                  const SizedBox(height: 30),
                  const BrandKicker('С возвращением', onDark: true, fontSize: 10.5),
                  const SizedBox(height: 12),
                  Text(
                    'Вход',
                    style: pochaevsk(
                      fontSize: 40,
                      color: BrandColors.onNeedles,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 38),
                  _buildAuthField(
                    controller: _emailController,
                    hint: 'Электронная почта',
                    keyboardType: TextInputType.emailAddress,
                    prefix: Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: BrandColors.onNeedles.withOpacity(0.7),
                    ),
                    validator: (value) =>
                        RegisterContactValidation.validateContact(value ?? ''),
                  ),
                  const SizedBox(height: 13),
                  _buildAuthField(
                    controller: _passwordController,
                    hint: 'Пароль',
                    obscureText: _obscurePassword,
                    prefix: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: BrandColors.onNeedles.withOpacity(0.7),
                    ),
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Text(
                        _obscurePassword ? 'Показать' : 'Скрыть',
                        style: BrandUi.inter(
                          fontSize: 12.5,
                          color: BrandColors.onNeedles.withOpacity(0.6),
                        ),
                      ),
                    ),
                    validator: (value) {
                      final issues = _passwordIssues(value ?? '');
                      if (issues.isEmpty) return null;
                      return issues.join('\n');
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: BrandColors.dawn,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Забыли пароль?',
                        style: BrandUi.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BrandColors.dawn,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (auth.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SelectableText(
                                auth.error!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          BrandAccentButton(
                            label: auth.isLoading ? 'Входим…' : 'Войти',
                            onPressed: auth.isLoading ? null : _handleLogin,
                          ),
                          const SizedBox(height: 18),
                          if (widget.onRegisterTap != null)
                            Text.rich(
                              TextSpan(
                                style: BrandUi.inter(
                                  fontSize: 14,
                                  color: BrandColors.onNeedles.withOpacity(0.7),
                                ),
                                children: [
                                  const TextSpan(text: 'Нет аккаунта? '),
                                  TextSpan(
                                    text: 'Регистрация',
                                    style: BrandUi.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BrandColors.onNeedles,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = widget.onRegisterTap,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefix,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: BrandUi.inter(fontSize: 15.5, color: BrandColors.onNeedles),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: BrandUi.inter(
          fontSize: 15.5,
          color: BrandColors.onNeedles.withOpacity(0.5),
        ),
        prefixIcon: prefix,
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffix,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.55), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
    );
  }

  List<String> _passwordIssues(String value) {
    final issues = <String>[];
    if (value.isEmpty) return ['Введите пароль'];
    if (value.length < 6) {
      issues.add('Минимум 6 символов');
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      issues.add('Добавьте буквы латиницы');
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      issues.add('Добавьте хотя бы одну цифру');
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      issues.add('Добавьте специальный символ');
    }
    return issues;
  }
}
