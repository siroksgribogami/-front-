import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_marketplace_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import 'appearance_screen.dart';
import 'admin_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'security_settings_screen.dart';
import 'language_settings_screen.dart';
import 'widgets/marketplace_profile_sections.dart';

/// Экран профиля пользователя
class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvatarPath();
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString('avatar_path');
    });
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar_path', image.path);
        setState(() {
          _avatarPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки изображения: $e')),
        );
      }
    }
  }

  Future<void> _editDisplayName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Изменить имя'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Отображаемое имя',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty || result == current) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.setDisplayName(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Имя обновлено' : 'Не удалось обновить имя'),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : MarketplaceColors.background;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : MarketplaceColors.textPrimary;
    final textHintC = isDark ? AppTheme.darkTextHint : MarketplaceColors.textSecondary;
    final dividerColor = isDark ? AppTheme.darkBorder.withOpacity(0.4) : null;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Профиль')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final width = MediaQuery.sizeOf(context).width;
          final horizontalPad = width >= 1200
              ? 96.0
              : width >= 900
                  ? 72.0
                  : width >= 600
                      ? 32.0
                      : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 20),
            children: [
              if (widget.embedded) ...[
                Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyle.fontFamily,
                    color: textMain,
                    height: AppTextStyle.defaultHeight,
                    leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Аватар и имя — красивая карточка
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
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              image: _avatarPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(_avatarPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _avatarPath == null 
                                ? Center(
                                    child: Text(
                                      user.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontFamily: AppTextStyle.fontFamily,
                                        height: AppTextStyle.defaultHeight,
                                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                                      ),
                                    ),
                                  )
                                : null,
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTextStyle.fontFamily,
                              color: textMain,
                              height: AppTextStyle.defaultHeight,
                              leadingDistribution:
                                  AppTextStyle.defaultLeadingDistribution,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Изменить имя',
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: textHintC),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                              minHeight: 32, minWidth: 32),
                          onPressed: () => _editDisplayName(context, user.username),
                        ),
                      ],
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

              Consumer<RoleProvider>(
                builder: (context, roles, _) {
                  if (roles.activeRole != AppMarketplaceRole.master ||
                      !roles.masterEnabled) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      _buildMarketplaceStatsCard(
                          context, cardBg, textMain, textHintC, isDark),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // --- Маркетплейс: роль (заказчик / мастер) и контент ЛК по активной роли ---
              const MarketplaceRoleCard(),
              const SizedBox(height: 16),
              Consumer<RoleProvider>(
                builder: (context, roles, _) {
                  if (roles.activeRole == AppMarketplaceRole.customer &&
                      roles.customerEnabled) {
                    return const Column(
                      children: [
                        MarketplaceCustomerSection(),
                        SizedBox(height: 16),
                      ],
                    );
                  }
                  if (roles.activeRole == AppMarketplaceRole.master &&
                      roles.masterEnabled) {
                    return const Column(
                      children: [
                        MarketplaceMasterSection(),
                        SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

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
                        _openNestedSettings(context, const NotificationSettingsScreen());
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsRow(
                      context,
                      icon: Icons.lock_outline,
                      label: 'Безопасность',
                      onTap: () {
                        _openNestedSettings(context, const SecuritySettingsScreen());
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsRow(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Внешний вид',
                      onTap: () {
                        _openNestedSettings(context, const AppearanceScreen());
                      },
                    ),
                    Divider(height: 1, indent: 56, color: dividerColor),
                    _buildSettingsRow(
                      context,
                      icon: Icons.language_outlined,
                      label: 'Язык',
                      onTap: () {
                        _openNestedSettings(context, const LanguageSettingsScreen());
                      },
                    ),
                    Divider(height: 1, indent: 56, color: dividerColor),
                    if (auth.premiseType == 'commerce' || user.isAdmin) ...[
                      Divider(height: 1, indent: 56, color: dividerColor),
                      _buildSettingsRow(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Админ',
                        onTap: () {
                          _openNestedSettings(context, const AdminSettingsScreen());
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

  Future<void> _openNestedSettings(BuildContext context, Widget screen) async {
    final media = MediaQuery.sizeOf(context);
    final useDialog = widget.embedded && media.width >= 980;
    if (useDialog) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: SizedBox(
            width: math.min(980, media.width - 120),
            height: math.min(780, media.height - 80),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: screen,
            ),
          ),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  String _accountModeLabel(String? mode) {
    switch (mode) {
      case 'customer':
        return 'Заказчик';
      case 'master':
        return 'Мастер';
      case 'b2b':
        return 'B2B (офисы/склады)';
      case 'p2p':
        return 'P2P (на заказ)';
      case 'service':
        return 'Услуги (временный доступ)';
      case 'b2c':
      default:
        return 'B2C (ремонт жилья)';
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
  
  /// Карточка статистики по заказам/отзывам/доходу.
  Widget _buildMarketplaceStatsCard(
    BuildContext context,
    Color cardBg,
    Color textMain,
    Color textHint,
    bool isDark,
  ) {
    return Container(
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
            'Статистика',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: AppTextStyle.fontFamily,
              color: textMain,
            ),
          ),
          const SizedBox(height: 16),
          
          // Основные показатели
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentColor.withOpacity(0.9),
                        AppTheme.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      const Text(
                        '128',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'всего заказов',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'средний рейтинг',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Наработано: 1 820 000 ₽ · Отзывов: 56',
              style: TextStyle(fontSize: 13, color: textHint),
            ),
          ),
        ],
      ),
    );
  }
}
