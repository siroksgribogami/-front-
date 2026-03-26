import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/apartment_provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import 'appearance_screen.dart';

/// Экран профиля пользователя
class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final apartmentProvider = context.read<ApartmentProvider>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      apartmentProvider.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textHintC = isDark ? AppTheme.darkTextHint : AppTheme.textHint;
    final dividerColor = isDark ? AppTheme.darkBorder.withOpacity(0.4) : null;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: embedded
          ? null
          : AppBar(title: const Text('Профиль')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            children: [
              if (embedded) ...[
                Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyle.fontFamily,
                    color: textMain,
                    height: AppTextStyle.defaultHeight,
                    leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Аватар и имя — красивая карточка
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: выбор аватарки (image_picker)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Загрузка аватарки — скоро')),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: AppTextStyle.fontFamily,
                                  height: AppTextStyle.defaultHeight,
                                  leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user.username,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTextStyle.fontFamily,
                        color: textMain,
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: textHintC,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Информация об аккаунте
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTextStyle.fontFamily,
                          color: textMain,
                          height: AppTextStyle.defaultHeight,
                          leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        icon: Icons.person_outline,
                        label: 'Имя пользователя',
                        value: user.username,
                      ),
                      _buildInfoRow(
                        context,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      _buildInfoRow(
                        context,
                        icon: Icons.verified_user_outlined,
                        label: 'Статус',
                        value: user.isActive ? 'Активен' : 'Неактивен',
                        valueColor:
                            user.isActive ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      _buildInfoRow(
                        context,
                        icon: Icons.badge_outlined,
                        label: 'Тип аккаунта',
                        value: _accountModeLabel(auth.accountMode),
                      ),
                      if (auth.usageMode != null)
                        _buildInfoRow(
                          context,
                          icon: Icons.people_outline,
                          label: 'Режим использования',
                          value: _usageModeLabel(auth.usageMode),
                        ),
                      _buildInfoRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Дата регистрации',
                        value: DateFormat('dd MMMM yyyy', 'ru')
                            .format(user.createdAt),
                        showDivider: false,
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 20),

              // Настройки
              Text(
                'Настройки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyle.fontFamily,
                  color: textMain,
                  height: AppTextStyle.defaultHeight,
                  leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Настройки уведомлений',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Настройки уведомлений — скоро')),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsRow(
                      context,
                      icon: Icons.lock_outline,
                      label: 'Безопасность',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsRow(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Внешний вид',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppearanceScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: dividerColor),
                    _buildSettingsRow(
                      context,
                      icon: Icons.language_outlined,
                      label: 'Язык',
                      onTap: () {
                        // TODO: выбор языка
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Выбор языка — скоро')),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: dividerColor),
                    _buildSettingsRow(
                      context,
                      icon: Icons.family_restroom_outlined,
                      label: 'Семейная связь',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пригласить членов семьи — скоро')),
                        );
                      },
                    ),
                    if (auth.premiseType == 'commerce' || user.isAdmin) ...[
                      Divider(height: 1, indent: 56, color: dividerColor),
                      _buildSettingsRow(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Админ',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Управление складом / админ — скоро')),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Кнопка выхода — стильная
              GestureDetector(
                onTap: () => _handleLogout(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Выйти из аккаунта',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Версия приложения
              Center(
                child: Text(
                  'АРТхаус v1.0.0',
                  style: TextStyle(
                    color: textHintC,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  String _accountModeLabel(String? mode) {
    switch (mode) {
      case 'b2b':
        return 'B2B (офисы/склады)';
      case 'p2p':
        return 'P2P (на заказ)';
      case 'service':
        return 'Услуги (временный доступ)';
      case 'b2c':
      default:
        return 'B2C (дом/квартира)';
    }
  }

  String _usageModeLabel(String? mode) {
    switch (mode) {
      case 'family':
        return 'Семейный';
      case 'business':
        return 'Бизнес';
      case 'personal':
      default:
        return 'Для себя';
    }
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textHint = isDark ? AppTheme.darkTextSecondary : AppTheme.textHint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textMain,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool showDivider = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textHint = isDark ? AppTheme.darkTextHint : AppTheme.textHint;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textHint,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: valueColor ?? textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder.withOpacity(0.35) : null,
          ),
      ],
    );
  }
}
