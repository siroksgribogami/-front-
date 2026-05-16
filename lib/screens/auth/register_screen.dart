import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../providers/auth_provider.dart';
import '../../utils/password_validation.dart';
import '../../utils/register_contact_validation.dart';

/// Порядок по ТЗ: имя → контакт → пароль → роль → запрос на сервер.
enum _RegisterStep { name, contact, password, role }

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
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _RegisterStep _step = _RegisterStep.name;
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
      begin: const Offset(0, 0.04),
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
    _nameController.dispose();
    _contactController.dispose();
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
    if (_step == _RegisterStep.name) {
      _handleBackToLogin();
      return;
    }
    setState(() {
      _step = switch (_step) {
        _RegisterStep.contact => _RegisterStep.name,
        _RegisterStep.password => _RegisterStep.contact,
        _RegisterStep.role => _RegisterStep.password,
        _RegisterStep.name => _RegisterStep.name,
      };
    });
    context.read<AuthProvider>().clearError();
  }

  void _handleNext() {
    if (!_validateCurrentStep()) return;
    context.read<AuthProvider>().clearError();

    if (_step == _RegisterStep.role) {
      _handleRegister();
      return;
    }

    setState(() {
      _step = switch (_step) {
        _RegisterStep.name => _RegisterStep.contact,
        _RegisterStep.contact => _RegisterStep.password,
        _RegisterStep.password => _RegisterStep.role,
        _RegisterStep.role => _RegisterStep.role,
      };
    });
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case _RegisterStep.name:
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          _formKey.currentState?.validate();
          return false;
        }
        if (name.length < 2) return false;
        if (name.length > 50) return false;
        return true;
      case _RegisterStep.contact:
        return _formKey.currentState?.validate() ?? false;
      case _RegisterStep.password:
        return _formKey.currentState?.validate() ?? false;
      case _RegisterStep.role:
        return true;
    }
  }

  Future<void> _handleRegister() async {
    if (_submitLock) return;
    if (!_validateCurrentStep()) return;

    setState(() => _submitLock = true);
    final authProvider = context.read<AuthProvider>();
    final parsed = RegisterContactValidation.parseForApi(_contactController.text);

    final success = await authProvider.register(
      email: parsed.email,
      username: _nameController.text.trim(),
      password: _passwordController.text,
      phone: parsed.phone,
      role: _selectedRole,
    );

    if (success && mounted) {
      widget.onRegisterSuccess?.call();
    }
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
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
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._buildStepContent(),
                              const SizedBox(height: 16),
                              _buildErrorBanner(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomNav(),
                if (_step == _RegisterStep.name) ...[
                  const SizedBox(height: 4),
                  _buildLoginLink(),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepContent() {
    return switch (_step) {
      _RegisterStep.name => _buildNameStep(),
      _RegisterStep.contact => _buildContactStep(),
      _RegisterStep.password => _buildPasswordStep(),
      _RegisterStep.role => _buildRoleStep(),
    };
  }

  List<Widget> _buildNameStep() {
    return [
      _buildTitle('Как вас зовут?'),
      const SizedBox(height: 28),
      _buildTextField(
        controller: _nameController,
        label: 'Ваше имя',
        textAlign: TextAlign.center,
        onChanged: (_) => context.read<AuthProvider>().clearError(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Введите имя';
          if (value.trim().length < 2) return 'Минимум 2 символа';
          if (value.trim().length > 50) return 'Не длиннее 50 символов';
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildContactStep() {
    return [
      _buildTitle('Email или телефон'),
      const SizedBox(height: 8),
      Text(
        'Укажите способ связи',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 28),
      _buildTextField(
        controller: _contactController,
        label: 'Email или телефон',
        keyboardType: TextInputType.emailAddress,
        textAlign: TextAlign.center,
        onChanged: (_) => context.read<AuthProvider>().clearError(),
        suffixIcon: _buildContactValidationIcon(),
        validator: (_) =>
            RegisterContactValidation.validateContact(_contactController.text),
      ),
    ];
  }

  List<Widget> _buildPasswordStep() {
    return [
      _buildTitle('Придумайте пароль'),
      const SizedBox(height: 28),
      _buildTextField(
        controller: _passwordController,
        label: 'Пароль',
        obscureText: _obscurePassword,
        textAlign: TextAlign.center,
        onChanged: (_) => context.read<AuthProvider>().clearError(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        validator: (value) {
          final v = value ?? '';
          if (v.isEmpty) return 'Введите пароль';
          if (!PasswordValidation.isAcceptable(v)) {
            return PasswordValidation.unsatisfiedSummary(v);
          }
          return null;
        },
      ),
      if (_passwordController.text.isNotEmpty) ...[
        const SizedBox(height: 12),
        _PasswordStrengthPanel(password: _passwordController.text),
      ],
      const SizedBox(height: 14),
      _buildTextField(
        controller: _confirmPasswordController,
        label: 'Подтвердите пароль',
        obscureText: _obscureConfirmPassword,
        textAlign: TextAlign.center,
        onChanged: (_) => context.read<AuthProvider>().clearError(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: () =>
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Подтвердите пароль';
          if (value != _passwordController.text) return 'Пароли не совпадают';
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildRoleStep() {
    return [
      _buildTitle('Вы пришли сюда как'),
      const SizedBox(height: 8),
      Text(
        'Дальше — разные вопросы для заказчика и мастера',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 28),
      _buildRoleCard(
        role: 'customer',
        title: 'Заказчик',
        subtitle: 'Ищу мастера для ремонта',
      ),
      const SizedBox(height: 12),
      _buildRoleCard(
        role: 'master',
        title: 'Мастер',
        subtitle: 'Выполняю работы',
      ),
    ];
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamily: AppTextStyle.fontFamily,
        height: AppTextStyle.defaultHeight,
        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primaryColor : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: selected
                    ? AppTheme.primaryColor.withOpacity(0.8)
                    : Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _step == _RegisterStep.role;
    final nextLabel = isLast ? 'Готово' : 'Далее';

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final loading = auth.isLoading || _submitLock;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OvalNavButton(
                label: 'Назад',
                outlined: true,
                onPressed: loading ? null : _handleBack,
              ),
              _OvalNavButton(
                label: nextLabel,
                loading: loading,
                onPressed: loading ? null : _handleNext,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.error == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            auth.error!,
            style: const TextStyle(color: Colors.white, height: 1.35),
            textAlign: TextAlign.center,
          ),
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
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _handleBackToLogin,
          child: const Text(
            'Войти',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextAlign textAlign = TextAlign.start,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textAlign: textAlign,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        alignLabelWithHint: textAlign == TextAlign.center,
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

class _OvalNavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;

  const _OvalNavButton({
    required this.label,
    this.onPressed,
    this.outlined = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : Colors.white,
      shape: StadiumBorder(
        side: outlined
            ? BorderSide(color: Colors.white.withOpacity(0.55))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: outlined ? Colors.white : AppTheme.primaryColor,
                    fontFamily: AppTextStyle.fontFamily,
                  ),
                ),
        ),
      ),
    );
  }
}

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
