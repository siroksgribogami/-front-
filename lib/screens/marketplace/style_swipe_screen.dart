import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/text_theme.dart';
import '../../core/theme/brand_runtime.dart';
import '../../core/theme/brand_ui.dart';

/// «Тиндер» вдохновения: свайпай стили ремонта вправо (нравится) / влево (мимо).
/// Лайки собираются в доску фаворитов и сохраняются в object_card.design.references.
///
/// ВАЖНО: контент кураторский, без скрапа Pinterest/Instagram. Реальные
/// картинки/Pinterest — будущая фича; интерфейс (возврат references) не изменится.
class StyleSwipeScreen extends StatefulWidget {
  const StyleSwipeScreen({super.key});

  static const prefsKey = 'arthouse_design_references';

  /// Открывает колоду. Возвращает список лайкнутых референсов (или null).
  static Future<List<Map<String, dynamic>>?> open(BuildContext context) {
    return Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute(builder: (_) => const StyleSwipeScreen()),
    );
  }

  @override
  State<StyleSwipeScreen> createState() => _StyleSwipeScreenState();
}

class _StyleSwipeScreenState extends State<StyleSwipeScreen> {
  static const _deck = <_StyleCard>[
    _StyleCard('Скандинавский', 'Светло, тепло, много дерева',
        ['светлый', 'дерево', 'минимум'], [Color(0xFFEDE6DA), Color(0xFFCBB79A)]),
    _StyleCard('Лофт', 'Кирпич, бетон, металл, лампы Эдисона',
        ['кирпич', 'бетон', 'индастриал'], [Color(0xFF6E6259), Color(0xFF3A332E)]),
    _StyleCard('Минимализм', 'Ничего лишнего, чистые линии',
        ['простота', 'белый', 'хранение'], [Color(0xFFF2F2F0), Color(0xFFBFC3C2)]),
    _StyleCard('Японди', 'Сканди + японская сдержанность',
        ['натуральный', 'спокойный', 'низкая мебель'], [Color(0xFFD9CBB8), Color(0xFF8C7A63)]),
    _StyleCard('Классика', 'Лепнина, симметрия, благородные тона',
        ['лепнина', 'симметрия', 'паркет'], [Color(0xFFE7DCC9), Color(0xFFA98D63)]),
    _StyleCard('Бохо', 'Текстиль, ротанг, зелень, уют',
        ['текстиль', 'ротанг', 'зелень'], [Color(0xFFE3C9A8), Color(0xFFB07A4F)]),
    _StyleCard('Хай-тек', 'Глянец, стекло, техника, чёткость',
        ['глянец', 'стекло', 'техно'], [Color(0xFFC2CBD2), Color(0xFF566069)]),
    _StyleCard('Прованс', 'Пастель, состаренное дерево, цветы',
        ['пастель', 'винтаж', 'уют'], [Color(0xFFEAE3EC), Color(0xFFB9A7C4)]),
  ];

  int _index = 0;
  Offset _drag = Offset.zero;
  final List<_StyleCard> _liked = [];

  bool get _finished => _index >= _deck.length;

  void _swipe(bool like) {
    if (_finished) return;
    if (like) _liked.add(_deck[_index]);
    setState(() {
      _index++;
      _drag = Offset.zero;
    });
  }

  Future<void> _finish() async {
    final refs = _liked
        .map((c) => <String, dynamic>{
              'style': c.title,
              'tags': c.tags,
              'source': 'style_swipe',
            })
        .toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StyleSwipeScreen.prefsKey, jsonEncode(refs));
    } catch (_) {
      // не критично — всё равно вернём результат экраном выше
    }
    if (!mounted) return;
    Navigator.of(context).pop(refs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: Column(
          children: [
            BrandAppBar(
              title: 'Вдохновение',
              subtitle: 'Свайпай стили — соберём доску фаворитов',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _finished ? _buildBoard() : _buildDeck(),
            ),
            if (!_finished) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeck() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          Text(
            'Нравится — вправо, мимо — влево',
            style: BrandUi.inter(
              fontSize: 13,
              color: BrandRuntime.ink.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // следующая карта (фон)
                if (_index + 1 < _deck.length)
                  Transform.scale(
                    scale: 0.94,
                    child: _card(_deck[_index + 1], faded: true),
                  ),
                // текущая карта (перетаскиваемая)
                GestureDetector(
                  onPanUpdate: (d) => setState(() => _drag += d.delta),
                  onPanEnd: (_) {
                    if (_drag.dx.abs() > 110) {
                      _swipe(_drag.dx > 0);
                    } else {
                      setState(() => _drag = Offset.zero);
                    }
                  },
                  child: Transform.translate(
                    offset: _drag,
                    child: Transform.rotate(
                      angle: _drag.dx / 1400,
                      child: _card(_deck[_index]),
                    ),
                  ),
                ),
                if (_drag.dx > 40) _stamp('НРАВИТСЯ', Colors.green, left: false),
                if (_drag.dx < -40) _stamp('МИМО', Colors.redAccent, left: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_index + 1} / ${_deck.length}  ·  лайков: ${_liked.length}',
            style: BrandUi.inter(
              fontSize: 12.5,
              color: BrandRuntime.ink.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(_StyleCard c, {bool faded = false}) {
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.colors,
          ),
          boxShadow: faded
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              Text(
                c.title,
                style: pochaevsk(fontSize: 30, color: Colors.white, height: 1.05),
              ),
              const SizedBox(height: 8),
              Text(
                c.subtitle,
                style: BrandUi.inter(
                  fontSize: 15,
                  height: 1.35,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: c.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t,
                            style: BrandUi.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stamp(String text, Color color, {required bool left}) {
    return Align(
      alignment: left ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Transform.rotate(
          angle: left ? 0.35 : -0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 6, 24, 12 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundBtn(Icons.close_rounded, Colors.redAccent, () => _swipe(false)),
          const SizedBox(width: 40),
          _roundBtn(Icons.favorite_rounded, Colors.green, () => _swipe(true)),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: BrandRuntime.card,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _liked.isEmpty ? 'Доска пока пустая' : 'Доска фаворитов',
            style: pochaevsk(fontSize: 24, color: BrandRuntime.ink),
          ),
          const SizedBox(height: 6),
          Text(
            _liked.isEmpty
                ? 'Вы ничего не выбрали — можно пройти ещё раз.'
                : 'Эти стили станут референсом — ИИ-прораб учтёт их в проекте.',
            style: BrandUi.inter(
              fontSize: 13.5,
              color: BrandRuntime.ink.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _liked.isEmpty
                ? const SizedBox.shrink()
                : GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: _liked.map((c) => _card(c)).toList(),
                  ),
          ),
          const SizedBox(height: 8),
          if (_liked.isEmpty)
            BrandGhostButton(
              label: 'Пройти заново',
              onPressed: () => setState(() {
                _index = 0;
                _liked.clear();
              }),
            )
          else
            BrandPrimaryButton(
              label: 'Добавить в проект (${_liked.length})',
              onPressed: _finish,
            ),
        ],
      ),
    );
  }
}

class _StyleCard {
  final String title;
  final String subtitle;
  final List<String> tags;
  final List<Color> colors;

  const _StyleCard(this.title, this.subtitle, this.tags, this.colors);
}
