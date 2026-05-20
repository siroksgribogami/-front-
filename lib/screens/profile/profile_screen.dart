import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_marketplace_role.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import 'account_settings_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAvatarPath();
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _avatarPath = prefs.getString('avatar_path'));
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
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 24),
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
              _buildProfileHeader(
                user: user,
                cardBg: cardBg,
                textMain: textMain,
                textHintC: textHintC,
                isDark: isDark,
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
                        context,
                        cardBg,
                        textMain,
                        textHintC,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
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
              Text(
                'Настройки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyle.fontFamily,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(context, auth, cardBg, dividerColor, isDark),
              const SizedBox(height: 28),
              _buildLogoutButton(context, cardBg),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'АРТхаус v1.0.0',
                  style: TextStyle(color: textHintC, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader({
    required User user,
    required Color cardBg,
    required Color textMain,
    required Color textHintC,
    required bool isDark,
  }) {
    DecorationImage? avatarImage;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      avatarImage = DecorationImage(
        image: FileImage(File(_avatarPath!)),
        fit: BoxFit.cover,
      );
    } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      avatarImage = DecorationImage(
        image: NetworkImage(user.avatarUrl!),
        fit: BoxFit.cover,
      );
    }

    final subtitle = user.contactSubtitle;

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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(18),
              image: avatarImage,
            ),
            child: avatarImage == null
                ? Center(
                    child: Text(
                      user.avatarInitial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: AppTextStyle.fontFamily,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.visibleName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyle.fontFamily,
                    color: textMain,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: textHintC),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    AuthProvider auth,
    Color cardBg,
    Color? dividerColor,
    bool isDark,
  ) {
    final user = auth.user;
    return Container(
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
            icon: Icons.person_outline,
            label: 'Аккаунт',
            onTap: () async {
              await _openNestedSettings(context, const AccountSettingsScreen());
              if (mounted) _loadAvatarPath();
            },
          ),
          const Divider(height: 1, indent: 56),
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
          if (auth.premiseType == 'commerce' || (user?.isAdmin ?? false)) ...[
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
    );
  }

  Widget _buildLogoutButton(BuildContext context, Color cardBg) {
    return GestureDetector(
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
