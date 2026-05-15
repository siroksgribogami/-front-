import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../utils/password_validation.dart';

/// Экран регистрации - в стиле HTML дизайна
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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    ).animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOutCubic));
    _transitionCtrl.forward();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Нажатие «Войти» — сначала анимация ухода, потом callback
  void _handleBackToLogin() {
    _transitionCtrl.reverse().then((_) {
      widget.onLoginTap?.call();
    });
  }

  Future<void> _handleRegister() async {
    if (_submitLock) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitLock = true);
    final authProvider = context.read<AuthProvider>();
    // Если пользователь указал телефон, но не email — создаём служебный email
    var email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty && phone.isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      email = '$digits@phone.arthouse.local';
    }

    final success = await authProvider.register(
      email: email,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      phone: phone.isEmpty ? null : phone,
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
              onPressed: _handleBackToLogin,
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 820;
                final sidePadding = compact ? 20.0 : 32.0;
                final topBottomPadding = compact ? 14.0 : 24.0;
                final sectionGap = compact ? 20.0 : 32.0;
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
                              'Создайте аккаунт для начала работы',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: sectionGap),

                            // Имя пользователя
                            _buildTextField(
                  controller: _usernameController,
                  label: 'Имя',
                  onChanged: (_) =>
                      context.read<AuthProvider>().clearError(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя';
                    }
                    if (value.length < 2) {
                      return 'Имя: минимум 2 символа';
                    }
                    if (value.length > 50) {
                      return 'Имя: не длиннее 50 символов';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldGap),

                // Email поле
                // Выбор способа контакта и поля
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // переключаемся на Email — очищаем телефон
                          setState(() {
                            _phoneController.text = '';
                          });
                        },
                        child: const Text('Email'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // переключаемся на телефон — очищаем email
                          setState(() {
                            _emailController.text = '';
                          });
                        },
                        child: const Text('Телефон'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: fieldGap),

                // Email поле (необязательное, если указан телефон)
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (рекомендуется)',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    setState(() {});
                    context.read<AuthProvider>().clearError();
                  },
                  suffixIcon: _buildEmailValidationIcon(),
                  validator: (value) {
                    if ((_phoneController.text.trim().isEmpty) &&
                        (value == null || value.isEmpty)) {
                      return 'Введите email или телефон';
                    }
                    if (value != null && value.isNotEmpty) {
                      return _validateEmailForRegister(value);
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldGap),

                // Телефон (необязательный)
                _buildTextField(
                  controller: _phoneController,
                  label: 'Телефон',
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    setState(() {});
                    context.read<AuthProvider>().clearError();
                  },
                  suffixIcon: _buildPhoneValidationIcon(),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.trim().isEmpty && _emailController.text.trim().isEmpty) {
                      return 'Введите email или телефон';
                    }
                    final err = _validatePhoneForRegister(v);
                    // при пустом телефоне и заполненном email — валидно
                    if (v.trim().isEmpty && _emailController.text.trim().isNotEmpty) return null;
                    return err;
                  },
                ),
                SizedBox(height: fieldGap),

                // Пароль поле
                _buildTextField(
                  controller: _passwordController,
                  label: 'Пароль',
                  obscureText: _obscurePassword,
                  onChanged: (_) =>
                      context.read<AuthProvider>().clearError(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
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

                // Подтверждение пароля
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Подтвердите пароль',
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) =>
                      context.read<AuthProvider>().clearError(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли должны совпадать';
                    }
                    return null;
                  },
                ),
                SizedBox(height: sectionGap),

                // Выбор роли: заказчик / мастер
                AppText(
                  'Вы пришли как',
                  style: AppTextStyle.gropled(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'customer'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),

                // Ошибка
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
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
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Кнопка регистрации
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: (auth.isLoading || _submitLock) ? null : _handleRegister,
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
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : const Text('Создать аккаунт'),
                    );
                  },
                ),
                SizedBox(height: compact ? 12 : 20),

                // Ссылка на вход
                Row(
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
                ),
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
  
  /// Поле ввода в стиле дизайна
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      validator: validator,
    );
  }

  String? _validateEmailForRegister(String rawValue) {
    final email = rawValue.trim();
    if (email.isEmpty) return 'Ошибка: пустой email';

    if (email.length > 254) {
      return 'Ошибка: длина email больше 254 символов';
    }

    if (email.contains(RegExp(r'\s'))) {
      return 'Ошибка: пробелы в email недопустимы';
    }

    final atCount = '@'.allMatches(email).length;
    if (atCount != 1) {
      return 'Ошибка: в адресе должна быть ровно одна @';
    }

    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1];

    if (local.isEmpty) {
      return 'Ошибка: локальная часть пустая';
    }
    if (local.length > 64) {
      return 'Ошибка: локальная часть длиннее 64 символов';
    }
    if (RegExp(r'[А-Яа-яЁё]').hasMatch(local)) {
      return 'Ошибка: кириллица в локальной части';
    }
    if (local.startsWith('.') || local.endsWith('.')) {
      return 'Ошибка: точка в начале или конце локальной части';
    }
    if (local.contains('..')) {
      return 'Ошибка: две точки подряд в локальной части';
    }
    if (!RegExp(r'^[A-Za-z0-9._+\-]+$').hasMatch(local)) {
      return 'Ошибка: недопустимые символы в локальной части';
    }

    if (domain.isEmpty) {
      return 'Ошибка: отсутствует домен';
    }
    if (RegExp(r'[А-Яа-яЁё]').hasMatch(domain)) {
      return 'Ошибка: кириллица в домене';
    }
    if (domain.startsWith('.') || domain.endsWith('.')) {
      return 'Ошибка: точка в начале или конце домена';
    }
    if (domain.contains('..')) {
      return 'Ошибка: две точки подряд в домене';
    }
    if (!RegExp(r'^[A-Za-z0-9.\-]+$').hasMatch(domain)) {
      return 'Ошибка: недопустимые символы в домене';
    }
    if (!domain.contains('.')) {
      return 'Ошибка: в домене нет зоны (например .com, .ru)';
    }

    final tld = domain.split('.').last;
    if (tld.length < 2) {
      return 'Ошибка: доменная зона слишком короткая';
    }

    final forbiddenDomains = <String>{'example.com', 'test.com', 'localhost'};
    if (forbiddenDomains.contains(domain.toLowerCase())) {
      return 'Ошибка: служебный домен недопустим';
    }

    return null;
  }

  Widget? _buildEmailValidationIcon() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return null;

    final error = _validateEmailForRegister(email);
    if (error == null) {
      return const Icon(
        Icons.check_circle,
        color: Color(0xFF81C784),
      );
    }

    return const Icon(
      Icons.error_outline,
      color: Colors.redAccent,
    );
  }

  String? _validatePhoneForRegister(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return 'Ошибка: поле не заполнено';

    // Плюс допустим только в начале
    if (raw.contains('+') && !raw.startsWith('+')) return 'Ошибка: недопустимый символ +';
    // 00 вместо +
    if (raw.startsWith('00')) return 'Ошибка: используйте +, а не 00';
    // Запрещаем буквы/кириллицу
    if (RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(raw)) return 'Ошибка: содержит буквы';
    // Разрешённые символы: цифры, +, пробел, (), -
    if (RegExp(r"[^0-9+()\s\-]").hasMatch(raw)) return 'Ошибка: недопустимые символы';

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Ошибка: номер содержит менее 10 цифр';
    if (digits.length > 11) return 'Ошибка: неверная длина, должно быть 10 или 11 цифр';

    if (digits.length == 11) {
      final first = digits[0];
      if (first != '7' && first != '8') return 'Ошибка: номер должен начинаться с 7 или 8';
      // нормализуем к виду, где ведущая цифра 7
      final normalized = (first == '8') ? '7${digits.substring(1)}' : digits;
      final code = normalized.substring(1, 4);
      if (code.length < 3) return 'Ошибка: недостаточно цифр';
      if (!code.startsWith('9')) return 'Ошибка: код оператора должен начинаться с 9';
      return null;
    }

    if (digits.length == 10) {
      if (!digits.startsWith('9')) return 'Ошибка: код оператора должен начинаться с 9';
      return null;
    }

    return 'Ошибка: неверная длина, должно быть 10 или 11 цифр';
  }

  Widget? _buildPhoneValidationIcon() {
    final val = _phoneController.text.trim();
    if (val.isEmpty) return null;
    final err = _validatePhoneForRegister(val);
    if (err == null) {
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
                  r.satisfied ? Icons.check_circle_outline : Icons.radio_button_unchecked,
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
