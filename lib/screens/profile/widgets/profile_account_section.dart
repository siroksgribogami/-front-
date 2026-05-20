import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../models/user.dart';

/// Карточка «Аккаунт»: аватар, имя, телефон, email.
class ProfileAccountSection extends StatelessWidget {
  final User user;
  final String? localAvatarPath;
  final VoidCallback onPickAvatar;
  final VoidCallback onEditName;
  final VoidCallback? onEditPhone;
  final String accountModeLabel;
  final Color cardBg;
  final Color textMain;
  final Color textHint;
  final bool isDark;
  final bool showSectionTitle;

  const ProfileAccountSection({
    super.key,
    required this.user,
    required this.localAvatarPath,
    required this.onPickAvatar,
    required this.onEditName,
    this.onEditPhone,
    required this.accountModeLabel,
    required this.cardBg,
    required this.textMain,
    required this.textHint,
    required this.isDark,
    this.showSectionTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final phone = user.displayPhone;
    final email = user.displayEmail;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSectionTitle) ...[
            Text(
              'Аккаунт',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: AppTextStyle.fontFamily,
                color: textMain,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: GestureDetector(
              onTap: onPickAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                      image: _avatarDecoration(),
                    ),
                    child: localAvatarPath == null &&
                            (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Center(
                            child: Text(
                              user.avatarInitial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: AppTextStyle.fontFamily,
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
          ),
          const SizedBox(height: 16),
          _editableRow(
            icon: Icons.person_outline,
            label: 'Имя',
            value: user.visibleName,
            onEdit: onEditName,
          ),
          _editableRow(
            icon: Icons.phone_outlined,
            label: 'Телефон',
            value: (phone != null && phone.isNotEmpty) ? phone : 'Не указан',
            onEdit: onEditPhone,
          ),
          if (email != null && email.isNotEmpty)
            _infoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Тип аккаунта',
            value: accountModeLabel,
          ),
          _infoRow(
            icon: Icons.verified_user_outlined,
            label: 'Статус',
            value: user.isActive ? 'Активен' : 'Неактивен',
            valueColor: user.isActive ? AppTheme.successColor : AppTheme.errorColor,
          ),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Дата регистрации',
            value: DateFormat('dd MMMM yyyy', 'ru').format(user.createdAt),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  DecorationImage? _avatarDecoration() {
    if (localAvatarPath != null && localAvatarPath!.isNotEmpty) {
      return DecorationImage(
        image: FileImage(File(localAvatarPath!)),
        fit: BoxFit.cover,
      );
    }
    final url = user.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _editableRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return _infoRow(
      icon: icon,
      label: label,
      value: value,
      trailing: onEdit == null
          ? null
          : IconButton(
              tooltip: 'Изменить',
              icon: Icon(Icons.edit_outlined, size: 18, color: textHint),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onEdit,
            ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: textHint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: textHint)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
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
