import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/register_contact_validation.dart';
import 'widgets/profile_account_section.dart';

/// Редактирование аккаунта: фото, имя, телефон, email.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String? _avatarPath;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_path', image.path);
      if (!mounted) return;
      setState(() => _avatarPath = image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки изображения: $e')),
      );
    }
  }

  Future<void> _editDisplayName(String current) async {
    final initial = current.trim();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _DisplayNameDialog(initial: initial),
    );
    if (!mounted || result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty || trimmed == initial) return;

    final ok = await context.read<AuthProvider>().setDisplayName(trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Имя обновлено' : 'Не удалось обновить имя')),
    );
  }

  Future<void> _editPhone(String? current) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _PhoneDialog(initial: current ?? ''),
    );
    if (!mounted || result == null) return;
    final err = RegisterContactValidation.validatePhone(result);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final ok = await context.read<AuthProvider>().setPhone(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Телефон обновлён' : 'Не удалось обновить телефон')),
    );
  }

  static String _accountModeLabel(String? mode) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textHint = isDark ? AppTheme.darkTextHint : AppTheme.textSecondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Аккаунт')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ProfileAccountSection(
                    user: user,
                    localAvatarPath: _avatarPath,
                    onPickAvatar: _pickAvatar,
                    onEditName: () => _editDisplayName(user.visibleName),
                    onEditPhone: () => _editPhone(
                      user.phone ??
                          user.displayPhone?.replaceAll(RegExp(r'[^\d+]'), ''),
                    ),
                    accountModeLabel: _accountModeLabel(auth.accountMode),
                    cardBg: cardBg,
                    textMain: textMain,
                    textHint: textHint,
                    isDark: isDark,
                    showSectionTitle: false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhoneDialog extends StatefulWidget {
  final String initial;
  const _PhoneDialog({required this.initial});

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Изменить телефон'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Номер телефона',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }
}

class _DisplayNameDialog extends StatefulWidget {
  final String initial;
  const _DisplayNameDialog({required this.initial});

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Изменить имя'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Отображаемое имя',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }
}
