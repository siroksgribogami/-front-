import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;
    final textMain = isDark ? const Color(0xFFEAE8E4) : const Color(0xFF2A3A2C);
    final textSub = isDark ? const Color(0xFFADABA6) : const Color(0xFF506A58);
    return Scaffold(
      appBar: AppBar(title: const Text('Язык')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(860, MediaQuery.sizeOf(context).width - 24)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: cardBg,
                child: RadioListTile<String>(
            value: 'ru',
            groupValue: _lang,
            title: Text('Русский', style: TextStyle(color: textMain)),
            subtitle: Text('Основной язык интерфейса', style: TextStyle(color: textSub)),
            onChanged: (v) => _setLang(v!),
          ),
              ),
              Card(
                elevation: 0,
                color: cardBg,
                child: RadioListTile<String>(
            value: 'en',
            groupValue: _lang,
            title: Text('English', style: TextStyle(color: textMain)),
            subtitle: Text('For multilingual interface', style: TextStyle(color: textSub)),
            onChanged: (v) => _setLang(v!),
          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
