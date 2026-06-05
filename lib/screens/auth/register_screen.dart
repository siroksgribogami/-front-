import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
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
      // Перечитываем роль маркетплейса из prefs (она сохранена в AuthProvider.register)
      // — чтобы экран профиля/нижние вкладки сразу увидели «мастер» вместо дефолтного «заказчик».
      await context.read<RoleProvider>().load();
      if (!mounted) return;
      widget.onRegisterSuccess?.call();
    }
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _submitLock = false);
    }
  }

  int get _stepNumber => switch (_step) {
        _RegisterStep.name => 1,
        _RegisterStep.contact => 2,
        _RegisterStep.password => 3,
        _RegisterStep.role => 4,
      };

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: BrandColors.canvas,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: BrandColors.canvas,
            body: Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildStepHeader(),
                                const SizedBox(height: 26),
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
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Row(
      children: [
        BrandBackButton(onPressed: _handleBack),
        const SizedBox(width: 14),
        Expanded(
          child: BrandSteps(total: 4, active: _stepNumber),
        ),
        const SizedBox(width: 14),
        Text(
          'Шаг $_stepNumber / 4',
          style: BrandUi.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: BrandColors.tar.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIntro({
    required String kicker,
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandKicker(kicker, fontSize: 10.5),
        const SizedBox(height: 10),
        Text(
          title,
          style: pochaevsk(
            fontSize: _step == _RegisterStep.role ? 34 : 30,
            color: BrandColors.tar,
            height: 1.02,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: BrandUi.inter(
              fontSize: 14,
              color: BrandColors.tar.withOpacity(0.55),
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 26),
      ],
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
      _buildStepIntro(
        kicker: 'Регистрация',
        title: 'Давайте познакомимся',
        subtitle: 'Как к вам обращаться?',
      ),
      _buildTextField(
        controller: _nameController,
        label: 'Ваше имя',
        textAlign: TextAlign.start,
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
      _buildStepIntro(
        kicker: 'Контакт',
        title: 'Email или телефон',
      ),
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
      _buildStepIntro(
        kicker: 'Безопасность',
        title: 'Придумайте пароль',
      ),
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
            color: BrandColors.tar.withOpacity(0.45),
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
            color: BrandColors.tar.withOpacity(0.45),
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
      _buildStepIntro(
        kicker: 'Последний шаг',
        title: 'Кто вы в ремонте?',
        subtitle:
            'От роли зависит, что вы увидите первым — свои проекты или ленту заказов.',
      ),
      _buildRoleCard(
        role: 'customer',
        title: 'Заказчик',
        subtitle: 'Планирую ремонт, ищу мастеров и веду проект',
      ),
      const SizedBox(height: 13),
      _buildRoleCard(
        role: 'master',
        title: 'Мастер',
        subtitle: 'Беру заказы, отправляю отклики и сметы',
      ),
    ];
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRole == role;
    final isCustomer = role == 'customer';
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? BrandColors.linen.withOpacity(0.85)
              : BrandColors.milk,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? BrandColors.needles : BrandColors.borderSubtle,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: BrandColors.needles.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isCustomer ? BrandColors.needles : BrandColors.linen,
                borderRadius: BorderRadius.circular(14),
                border: isCustomer
                    ? null
                    : Border.all(color: BrandColors.borderSubtle),
              ),
              alignment: Alignment.center,
              child: isCustomer
                  ? const Icon(
                      Icons.home_outlined,
                      color: BrandColors.onNeedles,
                      size: 26,
                    )
                  : BrandAvatar(
                      name: title,
                      size: 52,
                      radius: 14,
                      tone: BrandAvatarTone.sand,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: pochaevsk(
                      fontSize: 22,
                      color: BrandColors.tar,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: BrandUi.inter(
                      fontSize: 13,
                      color: BrandColors.tar.withOpacity(0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? BrandColors.needles : Colors.transparent,
                border: Border.all(
                  color: selected ? BrandColors.needles : BrandColors.chipBorder,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: BrandColors.onNeedles,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _step == _RegisterStep.role;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final loading = auth.isLoading || _submitLock;

        if (isLast) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BrandColors.clay,
                        ),
                      ),
                    )
                  : BrandAccentButton(
                      label: 'Завершить регистрацию',
                      onPressed: _handleNext,
                    ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
          child: Row(
            children: [
              BrandGhostButton(
                label: 'Назад',
                onPressed: loading ? null : _handleBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BrandPrimaryButton(
                  label: 'Далее',
                  onPressed: loading ? null : _handleNext,
                ),
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
            color: BrandColors.surik.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BrandColors.surik.withOpacity(0.25)),
          ),
          child: SelectableText(
            auth.error!,
            style: BrandUi.inter(
              color: BrandColors.surik,
              height: 1.35,
            ),
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
          style: BrandUi.inter(
            color: BrandColors.tar.withOpacity(0.55),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _handleBackToLogin,
          child: Text(
            'Войти',
            style: BrandUi.inter(
              fontWeight: FontWeight.w600,
              color: BrandColors.tar,
              fontSize: 14,
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
      style: BrandUi.inter(fontSize: 15, color: BrandColors.tar),
      cursorColor: BrandColors.needles,
      decoration: BrandUi.inputDecoration(
        hint: label,
        suffix: suffixIcon,
      ).copyWith(
        errorBorder: OutlineInputBorder(
          borderRadius: BrandUi.buttonRadius,
          borderSide: const BorderSide(color: BrandColors.surik),
        ),
      ),
      validator: validator,
    );
  }

  Widget? _buildContactValidationIcon() {
    final value = _contactController.text.trim();
    if (value.isEmpty) return null;
    final error = RegisterContactValidation.validateContact(value);
    if (error == null) {
      return const Icon(Icons.check_circle, color: BrandColors.needlesLight);
    }
    return const Icon(Icons.error_outline, color: BrandColors.surik);
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
      PasswordStrength.weak => ('Слабый пароль', BrandColors.surik),
      PasswordStrength.medium => ('Средний уровень', BrandColors.gilded),
      PasswordStrength.strong => ('Надёжный пароль', BrandColors.needlesLight),
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
            backgroundColor: BrandColors.borderSubtle,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: BrandUi.inter(
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
                      ? BrandColors.needlesLight
                      : BrandColors.tar.withOpacity(0.35),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.label,
                    style: BrandUi.inter(
                      fontSize: 12,
                      height: 1.3,
                      color: r.satisfied
                          ? BrandColors.tar
                          : BrandColors.tar.withOpacity(0.55),
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
