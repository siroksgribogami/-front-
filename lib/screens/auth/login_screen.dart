import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';

/// Экран входа - в стиле HTML дизайна (шалфейно-зеленый фон)
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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      widget.onLoginSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showForm) return _buildWelcomeScreen();
    return _buildLoginForm();
  }
  
  /// Начальный экран в стиле дизайна
  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Vignette overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.08)],
                    stops: [0.55, 1.0],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'АРТхаус',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -2.5,
                        fontFamily: AppTextStyle.fontFamily,
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'твой дом в порядке',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 3,
                        fontFamily: AppTextStyle.fontFamily,
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        children: [
                          _buildPillButton(
                            label: 'Вход',
                            onTap: () => setState(() => _showForm = true),
                          ),
                          const SizedBox(height: 12),
                          _buildPillButton(
                            label: 'Регистрация',
                            outlined: true,
                            onTap: widget.onRegisterTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Форма входа
  Widget _buildLoginForm() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() => _showForm = false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Text(
                  'Вход',
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
                  'Рады видеть вас снова',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите email';
                    if (!_isValidEmail(value)) return 'Введите корректный email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Пароль',
                  obscureText: _obscurePassword,
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
                    final issues = _passwordIssues(value ?? '');
                    if (issues.isEmpty) return null;
                    return issues.join('\n');
                  },
                ),
                const SizedBox(height: 32),
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
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : const Text(
                              'Войти',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
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
  
  /// Поле ввода в стиле дизайна
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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

  Widget _buildPillButton({
    required String label,
    required VoidCallback? onTap,
    bool outlined = false,
  }) {
    final baseStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: outlined ? Colors.white : AppTheme.primaryColor,
      fontFamily: AppTextStyle.fontFamily,
      letterSpacing: 0.5,
      height: AppTextStyle.defaultHeight,
      leadingDistribution: AppTextStyle.defaultLeadingDistribution,
    );

    final decoration = BoxDecoration(
      color: outlined ? Colors.transparent : Colors.white,
      borderRadius: BorderRadius.circular(100),
      border: outlined
          ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
          : null,
      boxShadow: outlined
          ? null
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onTap == null ? 0.6 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: decoration,
          alignment: Alignment.center,
          child: Text(label, style: baseStyle),
        ),
      ),
    );
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
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
