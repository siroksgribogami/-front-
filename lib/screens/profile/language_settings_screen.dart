import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _lang = 'ru';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'ru';
      _loaded = true;
    });
  }

  Future<void> _setLang(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', value);
    if (!mounted) return;
    setState(() => _lang = value);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Язык сохранён. Применится после перезапуска.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const BrandScreen(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BrandScreen(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: BrandRuntime.canvas,
        foregroundColor: BrandRuntime.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: BrandAppBar(
            title: 'Язык',
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      padding: EdgeInsets.zero,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              BrandSettingsGroup(
                children: [
                  _LangRow(
                    flag: 'Ру',
                    name: 'Русский',
                    sub: 'Russian',
                    selected: _lang == 'ru',
                    onTap: () => _setLang('ru'),
                  ),
                  _LangRow(
                    flag: 'En',
                    name: 'English',
                    sub: 'Английский',
                    selected: _lang == 'en',
                    onTap: () => _setLang('en'),
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: BrandRuntime.surface.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: BrandRuntime.needles,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Язык приложения сменится сразу. Чаты и описания проектов остаются на языке оригинала.',
                        style: BrandUi.inter(
                          fontSize: 12.5,
                          color: BrandRuntime.needles,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.flag,
    required this.name,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.last = false,
  });

  final String flag;
  final String name;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(
                    bottom: BorderSide(color: BrandRuntime.border),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: BrandRuntime.canvas,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    flag,
                    style: pochaevsk(
                      fontSize: 15,
                      color: BrandRuntime.needles,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: BrandUi.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BrandRuntime.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sub,
                        style: BrandUi.inter(
                          fontSize: 12.5,
                          color: BrandRuntime.ink.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? BrandRuntime.needles : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? BrandRuntime.needles
                          : BrandRuntime.borderStrong,
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
        ),
      ),
    );
  }
}
