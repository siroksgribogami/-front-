import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../providers/auth_provider.dart';
import '../../utils/password_validation.dart';
import '../../utils/register_contact_validation.dart';

enum _RegisterStep { contact, role, credentials }

/// Регистрация: 1) email/телефон → 2) роль → 3) имя и пароль.
class RegisterScreen extends StatefulWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.onLoginTap,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _RegisterStep _step = _RegisterStep.contact;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitLock = false;
  String _selectedRole = 'customer';

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
    ).animate(
      CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOutCubic),
    );
    _transitionCtrl.forward();
    _passwordController.addListener(() => setState(() {}));
    _contactController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBackToLogin() {
    _transitionCtrl.reverse().then((_) {
      widget.onLoginTap?.call();
    });
  }

  void _handleBack() {
    if (_step == _RegisterStep.contact) {
      _handleBackToLogin();
      return;
    }
    setState(() {
      _step = _step == _RegisterStep.credentials
          ? _RegisterStep.role
          : _RegisterStep.contact;
    });
    context.read<AuthProvider>().clearError();
  }

  void _goNextFromContact() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = _RegisterStep.role);
    context.read<AuthProvider>().clearError();
  }

  void _goNextFromRole() {
    setState(() => _step = _RegisterStep.credentials);
    context.read<AuthProvider>().clearError();
  }

  Future<void> _handleRegister() async {
    if (_submitLock) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitLock = true);
    final authProvider = context.read<AuthProvider>();
    final parsed = RegisterContactValidation.parseForApi(_contactController.text);

    final success = await authProvider.register(
      email: parsed.email,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      phone: parsed.phone,
      role: _selectedRole,
    );

    if (success && mounted) {
      widget.onRegisterSuccess?.call();
    }
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _submitLock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Scaffold(
          backgroundColor: AppTheme.primaryColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _handleBack,
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 820;
                final sidePadding = compact ? 20.0 : 32.0;
                final topBottomPadding = compact ? 14.0 : 24.0;
                final sectionGap = compact ? 20.0 : 28.0;
                final fieldGap = compact ? 12.0 : 16.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    topBottomPadding,
                    sidePadding,
                    topBottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._buildStepContent(
                              compact: compact,
                              sectionGap: sectionGap,
                              fieldGap: fieldGap,
                            ),
                            SizedBox(height: sectionGap),
                            _buildErrorBanner(),
                            _buildPrimaryButton(),
                            SizedBox(height: compact ? 12 : 20),
                            _buildLoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepContent({
    required bool compact,
    required double sectionGap,
    required double fieldGap,
  }) {
    switch (_step) {
      case _RegisterStep.contact:
        return [
          const Text(
            'Регистрация',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: AppTextStyle.fontFamily,
              height: AppTextStyle.defaultHeight,
              leadingDistribution: AppTextStyle.defaultLeadingDistribution,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите email или номер телефона',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: sectionGap),
          _buildTextField(
            controller: _contactController,
            label: 'Email или телефон',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            suffixIcon: _buildContactValidationIcon(),
            validator: (_) =>
                RegisterContactValidation.validateContact(_contactController.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Телефон: +7 9XX XXX-XX-XX или 9XXXXXXXXX\n'
            'Email: name@example.com',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ];
      case _RegisterStep.role:
        return [
          const Text(
            'Вы пришли как?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: AppTextStyle.fontFamily,
              height: AppTextStyle.defaultHeight,
              leadingDistribution: AppTextStyle.defaultLeadingDistribution,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите роль в сервисе',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: sectionGap),
          _buildRoleSelector(),
        ];
      case _RegisterStep.credentials:
        return [
          const Text(
            'Почти готово',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: AppTextStyle.fontFamily,
              height: AppTextStyle.defaultHeight,
              leadingDistribution: AppTextStyle.defaultLeadingDistribution,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Имя и пароль для входа',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: sectionGap),
          _buildTextField(
            controller: _usernameController,
            label: 'Имя',
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Введите имя';
              if (value.length < 2) return 'Имя: минимум 2 символа';
              if (value.length > 50) return 'Имя: не длиннее 50 символов';
              return null;
            },
          ),
          SizedBox(height: fieldGap),
          _buildTextField(
            controller: _passwordController,
            label: 'Пароль',
            obscureText: _obscurePassword,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withOpacity(0.6),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Введите пароль';
              if (!PasswordValidation.isAcceptable(v)) {
                return 'Пароль: ${PasswordValidation.unsatisfiedSummary(v)}';
              }
              return null;
            },
          ),
          if (_passwordController.text.isNotEmpty) ...[
            SizedBox(height: compact ? 8 : 10),
            _PasswordStrengthPanel(password: _passwordController.text),
          ],
          SizedBox(height: fieldGap),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Подтвердите пароль',
            obscureText: _obscureConfirmPassword,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withOpacity(0.6),
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Подтвердите пароль';
              if (value != _passwordController.text) {
                return 'Пароли должны совпадать';
              }
              return null;
            },
          ),
        ];
    }
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = 'customer'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _selectedRole == 'customer'
                    ? Colors.white
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Я заказчик',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selectedRole == 'customer'
                      ? AppTheme.primaryColor
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = 'master'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _selectedRole == 'master'
                    ? Colors.white
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Я мастер',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selectedRole == 'master'
                      ? AppTheme.primaryColor
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.error == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              auth.error!,
              style: const TextStyle(color: Colors.white, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton() {
    final label = switch (_step) {
      _RegisterStep.contact || _RegisterStep.role => 'Далее',
      _RegisterStep.credentials => 'Создать аккаунт',
    };

    final onPressed = switch (_step) {
      _RegisterStep.contact => _goNextFromContact,
      _RegisterStep.role => _goNextFromRole,
      _RegisterStep.credentials => _handleRegister,
    };

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final loading = auth.isLoading || _submitLock;
        return ElevatedButton(
          onPressed: loading ? null : onPressed,
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
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                )
              : Text(label),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Уже есть аккаунт?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontFamily: AppTextStyle.fontFamily,
            fontSize: 14,
            height: AppTextStyle.defaultHeight,
          ),
        ),
        TextButton(
          onPressed: _handleBackToLogin,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyle.fontFamily,
              height: AppTextStyle.defaultHeight,
              leadingDistribution: AppTextStyle.defaultLeadingDistribution,
            ),
          ),
          child: const Text('Войти'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget? _buildContactValidationIcon() {
    final value = _contactController.text.trim();
    if (value.isEmpty) return null;

    final error = RegisterContactValidation.validateContact(value);
    if (error == null) {
      return const Icon(Icons.check_circle, color: Color(0xFF81C784));
    }
    return const Icon(Icons.error_outline, color: Colors.redAccent);
  }
}

/// Индикатор надёжности и чеклист требований к паролю.
class _PasswordStrengthPanel extends StatelessWidget {
  final String password;

  const _PasswordStrengthPanel({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = PasswordValidation.strength(password);
    final reqs = PasswordValidation.analyze(password);

    final (label, color) = switch (strength) {
      PasswordStrength.weak => ('Слабый пароль', const Color(0xFFE57373)),
      PasswordStrength.medium => ('Средний уровень', const Color(0xFFFFB74D)),
      PasswordStrength.strong => ('Надёжный пароль', const Color(0xFF81C784)),
    };

    final filled = reqs.where((r) => r.satisfied).length / reqs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: filled.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.15),
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ...reqs.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  r.satisfied
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: r.satisfied
                      ? const Color(0xFF81C784)
                      : Colors.white.withOpacity(0.45),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: r.satisfied
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
