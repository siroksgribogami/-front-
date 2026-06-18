import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/brand_colors.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/register_contact_validation.dart';

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

  ImageProvider? _avatarImage(User user) {
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      return FileImage(File(_avatarPath!));
    }
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return NetworkImage(user.avatarUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BrandScreen(
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: BrandAppBar(
              title: 'Аккаунт',
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final phone = user.displayPhone;
          final email = user.displayEmail;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              BrandAvatar(
                                name: user.visibleName,
                                size: 92,
                                radius: 26,
                                image: _avatarImage(user),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: BrandColors.clay,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: BrandRuntime.canvas,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 17,
                                    color: BrandColors.onClay,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Изменить фото',
                            style: BrandUi.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.clay,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  BrandLabeledField(
                    label: 'Имя и фамилия',
                    value: user.visibleName,
                    icon: Icon(Icons.person_outline,
                        size: 17, color: BrandRuntime.ink.withOpacity(0.55)),
                    onTap: () => _editDisplayName(user.visibleName),
                  ),
                  const SizedBox(height: 14),
                  BrandLabeledField(
                    label: 'Телефон',
                    value: (phone != null && phone.isNotEmpty)
                        ? phone
                        : 'Не указан',
                    icon: Icon(Icons.phone_outlined,
                        size: 17, color: BrandRuntime.ink.withOpacity(0.55)),
                    onTap: () => _editPhone(
                      user.phone ??
                          user.displayPhone?.replaceAll(RegExp(r'[^\d+]'), ''),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (email != null && email.isNotEmpty)
                    BrandLabeledField(
                      label: 'Электронная почта',
                      value: email,
                      icon: Icon(Icons.mail_outline,
                          size: 17, color: BrandRuntime.ink.withOpacity(0.55)),
                      trailing: Text(
                        'Подтв.',
                        style: BrandUi.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: BrandRuntime.needles,
                        ),
                      ),
                    ),
                  if (email != null && email.isNotEmpty)
                    const SizedBox(height: 14),
                  BrandLabeledField(
                    label: 'Город',
                    value: 'Москва',
                    icon: Icon(Icons.location_on_outlined,
                        size: 17, color: BrandRuntime.ink.withOpacity(0.55)),
                  ),
                  const SizedBox(height: 24),
                  BrandPrimaryButton(
                    label: 'Сохранить изменения',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Изменения сохраняются при редактировании полей'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
            ),
          ),
        ],
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
