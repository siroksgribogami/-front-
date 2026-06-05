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
import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/theme/brand_ui.dart';
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
    final cardBg = isDark ? AppTheme.darkCard : MarketplaceColors.card;
    final textMain = isDark ? AppTheme.darkTextPrimary : MarketplaceColors.textPrimary;
    final textHintC = isDark ? AppTheme.darkTextHint : MarketplaceColors.textSecondary;
    return Scaffold(
      backgroundColor: widget.embedded ? BrandColors.canvas : scaffoldBg,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Профиль'),
              backgroundColor: BrandColors.canvas,
            ),
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
                const BrandAppBar(title: 'Профиль', big: true),
                const SizedBox(height: 8),
              ],
              _buildProfileHeader(
                user: user,
                cardBg: cardBg,
                textMain: textMain,
                textHintC: textHintC,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildCustomerStatsRow(),
              const SizedBox(height: 16),
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
              _buildSettingsGroups(context, auth),
              const SizedBox(height: 28),
              _buildLogoutButton(context, cardBg),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Приделе v1.0.0',
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
    ImageProvider? avatarImage;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      avatarImage = FileImage(File(_avatarPath!));
    } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(user.avatarUrl!);
    }

    final subtitle = user.contactSubtitle;
    final role = context.watch<RoleProvider>().activeRole;
    final roleLabel =
        role == AppMarketplaceRole.master ? 'Мастер' : 'Заказчик';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.milk,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColors.borderSubtle),
      ),
      child: Row(
        children: [
          BrandAvatar(
            name: user.visibleName,
            size: 64,
            radius: 18,
            image: avatarImage,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.visibleName,
                  style: pochaevsk(fontSize: 22, color: BrandColors.tar, height: 1),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: BrandUi.inter(
                      fontSize: 13,
                      color: BrandColors.tar.withOpacity(0.55),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.linen.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: BrandColors.needlesLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        roleLabel,
                        style: BrandUi.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.needles,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          BrandIconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: BrandColors.needles),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatsRow() {
    return const Row(
      children: [
        Expanded(
          child: BrandStatTile(value: '3', label: 'проекта', centered: true),
        ),
        SizedBox(width: 10),
        Expanded(
          child: BrandStatTile(value: '10', label: 'откликов', centered: true),
        ),
        SizedBox(width: 10),
        Expanded(
          child: BrandStatTile(value: '4.9', label: 'рейтинг', centered: true),
        ),
      ],
    );
  }

  Widget _settingsIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: BrandColors.linen.withOpacity(0.7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: BrandColors.needles),
    );
  }

  Widget _buildSettingsGroups(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final showAdmin = auth.premiseType == 'commerce' || (user?.isAdmin ?? false);

    return Column(
      children: [
        BrandSettingsGroup(
          children: [
            BrandSettingsRow(
              icon: _settingsIcon(Icons.person_outline),
              label: 'Аккаунт',
              value: 'Имя, телефон, email',
              onTap: () async {
                await _openNestedSettings(context, const AccountSettingsScreen());
                if (mounted) _loadAvatarPath();
              },
            ),
            BrandSettingsRow(
              icon: _settingsIcon(Icons.notifications_outlined),
              label: 'Уведомления',
              onTap: () {
                _openNestedSettings(context, const NotificationSettingsScreen());
              },
            ),
            BrandSettingsRow(
              icon: _settingsIcon(Icons.lock_outline),
              label: 'Безопасность',
              onTap: () {
                _openNestedSettings(context, const SecuritySettingsScreen());
              },
              last: !showAdmin,
            ),
            if (showAdmin)
              BrandSettingsRow(
                icon: _settingsIcon(Icons.admin_panel_settings_outlined),
                label: 'Админ',
                onTap: () {
                  _openNestedSettings(context, const AdminSettingsScreen());
                },
                last: true,
              ),
          ],
        ),
        const SizedBox(height: 18),
        BrandSettingsGroup(
          children: [
            BrandSettingsRow(
              icon: _settingsIcon(Icons.brightness_6_outlined),
              label: 'Внешний вид',
              value: 'Светлая',
              onTap: () {
                _openNestedSettings(context, const AppearanceScreen());
              },
            ),
            BrandSettingsRow(
              icon: _settingsIcon(Icons.language_outlined),
              label: 'Язык',
              value: 'Русский',
              onTap: () {
                _openNestedSettings(context, const LanguageSettingsScreen());
              },
              last: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, Color cardBg) {
    return GestureDetector(
      onTap: () => _handleLogout(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: BrandColors.milk,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BrandColors.chipBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: BrandColors.surik, size: 18),
            const SizedBox(width: 9),
            Text(
              'Выйти из аккаунта',
              style: BrandUi.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BrandColors.surik,
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
              fontFamily: AppTextStyle.uiFontFamily,
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
