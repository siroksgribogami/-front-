import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/bar_loader.dart';
import '../../core/theme/app_text_style.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class PostRegisterSurveyScreen extends StatefulWidget {
  const PostRegisterSurveyScreen({super.key});

  @override
  State<PostRegisterSurveyScreen> createState() =>
      _PostRegisterSurveyScreenState();
}

class _PostRegisterSurveyScreenState extends State<PostRegisterSurveyScreen> {

  int _step = 1;
  static const int _totalSteps = 5;
  bool _isForward = true;

  // Подписи шагов
  static const _stepLabels = [
    'Ваш дом',
    'Детали',
    'Что важно',
    'Что изменить',
    'Атмосфера',
  ];

  // ─── ШАГ 1: Тип + Параметры ───────────────────────────────────────────────
  String? _premiseType;
  UserType _userType = UserType.b2c;

  // Тёмно-зелёный цвет иконок
  static const _iconColor = Color(0xFF243D2C);

  static const _premiseOptions = [
    {'id': 'apartment', 'label': 'Квартира',         'icon': Icons.apartment_outlined},
    {'id': 'house',     'label': 'Частный дом',      'icon': Icons.house_outlined},
    {'id': 'office',    'label': 'Офис',             'icon': Icons.business_center_outlined},
    {'id': 'commerce',  'label': 'Склад',            'icon': Icons.warehouse_outlined},
    {'id': 'hotel',     'label': 'Апартаменты',      'icon': Icons.hotel_outlined},
  ];

  // Конфигурации параметров по типу помещения
  static const Map<String, Map<String, dynamic>> _premiseConfigs = {
    'apartment': {
      'areaLabel':    'Площадь',
      'area':         ['до 30 м²', '30–50 м²', '50–80 м²', '80–120 м²', '120+ м²'],
      'defaultArea':  '50–80 м²',
      'ceilLabel':    'Высота потолков',
      'ceil':         ['240 см', '260 см', '280 см', '300+ см'],
      'defaultCeil':  '260 см',
      'floorsLabel':  'Этажей',
      'floors':       ['1', '2', '3', '4+'],
      'defaultFloors':'1',
      'roomsLabel':   'Комнат',
      'rooms':        ['1', '2', '3', '4', '5', '6+'],
      'defaultRooms': '3',
    },
    'house': {
      'areaLabel':    'Площадь',
      'area':         ['до 80 м²', '80–150 м²', '150–250 м²', '250–400 м²', '400+ м²'],
      'defaultArea':  '80–150 м²',
      'ceilLabel':    'Высота потолков',
      'ceil':         ['240 см', '260 см', '280 см', '300+ см'],
      'defaultCeil':  '260 см',
      'floorsLabel':  'Этажей',
      'floors':       ['1', '2', '3', '4+'],
      'defaultFloors':'2',
      'roomsLabel':   'Комнат',
      'rooms':        ['2', '3', '4', '5', '6', '7+'],
      'defaultRooms': '4',
    },
    'office': {
      'areaLabel':    'Площадь',
      'area':         ['до 30 м²', '30–100 м²', '100–300 м²', '300–500 м²', '500+ м²'],
      'defaultArea':  '30–100 м²',
      'ceilLabel':    'Высота',
      'ceil':         ['260 см', '280 см', '300 см', '320+ см'],
      'defaultCeil':  '280 см',
      'floorsLabel':  'Этажей',
      'floors':       ['1', '2', '3', '4+'],
      'defaultFloors':'1',
      'roomsLabel':   'Рабочих мест',
      'rooms':        ['до 5', '5–10', '10–20', '20–50', '50+'],
      'defaultRooms': '5–10',
    },
    'commerce': {
      'areaLabel':    'Площадь',
      'area':         ['до 100 м²', '100–500 м²', '500–2000 м²', '2000+ м²'],
      'defaultArea':  '100–500 м²',
      'ceilLabel':    'Высота',
      'ceil':         ['до 4 м', '4–6 м', '6–10 м', '10–12 м', '12+ м'],
      'defaultCeil':  '4–6 м',
      'floorsLabel':  'Этажей',
      'floors':       ['1', '2', '3+'],
      'defaultFloors':'1',
      'roomsLabel':   'Зон',
      'rooms':        ['1–2', '3–5', '5–10', '10+'],
      'defaultRooms': '1–2',
    },
    'hotel': {
      'areaLabel':    'Площадь',
      'area':         ['до 30 м²', '30–50 м²', '50–80 м²', '80–120 м²', '120+ м²'],
      'defaultArea':  '30–50 м²',
      'ceilLabel':    'Высота потолков',
      'ceil':         ['240 см', '260 см', '280 см', '300+ см'],
      'defaultCeil':  '260 см',
      'floorsLabel':  'Этажей',
      'floors':       ['1', '2+'],
      'defaultFloors':'1',
      'roomsLabel':   'Планировка',
      'rooms':        ['Студия', '1 комната', '2 комнаты', '3 комнаты', '4+'],
      'defaultRooms': '1 комната',
    },
  };

  String _totalArea     = '50–80 м²';
  String _ceilingHeight = '260 см';
  String _floorsCount   = '1';
  String _roomsCount    = '3';

  // ─── ШАГ 2: Приоритеты ────────────────────────────────────────────────────
  static const _priorities = [
    {'label': 'Порядок и чистота',           'emoji': '🧼'},
    {'label': 'Спокойствие и релакс',        'emoji': '😌'},
    {'label': 'Красота и стиль',             'emoji': '🎨'},
    {'label': 'Функциональность и удобство', 'emoji': '🛠️'},
    {'label': 'Семейная атмосфера',          'emoji': '👨‍👩‍👧‍👦'},
    {'label': 'Продуктивность',              'emoji': '💼'},
    {'label': 'Экономия времени',            'emoji': '⏰'},
    {'label': 'Экологичность',               'emoji': '🌿'},
  ];
  final Set<String> _selectedPriorities = {};

  // ─── ШАГ 3: Проблемные зоны ───────────────────────────────────────────────
  static const _problemZones = [
    {'label': 'Беспорядок в прихожей',          'emoji': '🚪'},
    {'label': 'Захламлённый балкон / кладовая', 'emoji': '📦'},
    {'label': 'Теснота на кухне',               'emoji': '🍽️'},
    {'label': 'Неудобная расстановка мебели',   'emoji': '🛋️'},
    {'label': 'Плохое освещение',               'emoji': '💡'},
    {'label': 'Шум',                            'emoji': '🔇'},
    {'label': 'Холодно / сыро',                 'emoji': '❄️'},
  ];
  final Set<String> _selectedProblems = {};
  final _otherCtrl = TextEditingController();

  // ─── ШАГ 4: Стиль ─────────────────────────────────────────────────────────
  final Set<String> _interiorStyles = {};
  static const _styles = [
    {'id': 'minimal',  'label': 'Минимализм',    'sub': 'чисто и просто',   'emoji': '⚪'},
    {'id': 'scandi',   'label': 'Скандинавский', 'sub': 'светло и уютно',   'emoji': '🌿'},
    {'id': 'loft',     'label': 'Лофт',          'sub': 'кирпич и металл',  'emoji': '🧱'},
    {'id': 'provence', 'label': 'Прованс',       'sub': 'тепло и мягко',    'emoji': '🌸'},
    {'id': 'hitech',   'label': 'Хай-тек',       'sub': 'технологично',     'emoji': '🔘'},
    {'id': 'classic',  'label': 'Классика',      'sub': 'традиционно',      'emoji': '🏛️'},
    {'id': 'eclectic', 'label': 'Эклектика',     'sub': 'свой стиль',       'emoji': '✨'},
    {'id': 'help',     'label': 'Нужна помощь',  'sub': 'подберём вместе',  'emoji': '💬'},
  ];

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  // ─── НАВИГАЦИЯ ─────────────────────────────────────────────────────────────

  void _next() {
    if (_step < _totalSteps) {
      setState(() { _isForward = true; _step++; });
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() { _isForward = false; _step--; });
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 1: return _premiseType != null;
      case 2: return true;
      case 3: return _selectedPriorities.isNotEmpty;
      case 4: return true; // шаг необязателен
      case 5: return _interiorStyles.isNotEmpty;
      default: return true;
    }
  }

  bool get _isSkippable =>
      _step == 4 && _selectedProblems.isEmpty && _otherCtrl.text.isEmpty;

  int _toAreaValue(String v) {
    final m = RegExp(r'\d+').firstMatch(v);
    return m != null ? int.parse(m.group(0)!) : 50;
  }

  int _toCeilingValue(String v) {
    // "260 см" → 260 ; "4–6 м" → 400 (переводим в см)
    final m = RegExp(r'\d+').firstMatch(v);
    if (m == null) return 260;
    final n = int.parse(m.group(0)!);
    return v.contains('м') && !v.contains('см') ? n * 100 : n;
  }

  int _toInt(String v, String plus) {
    final clean = v.replaceAll('+', '').replaceAll('≥', '');
    final m = RegExp(r'\d+').firstMatch(clean);
    return m != null ? int.parse(m.group(0)!) : 1;
  }

  /// Сбрасывает параметры на дефолт при смене типа
  void _applyConfig(String typeId) {
    final cfg = _premiseConfigs[typeId]!;
    _totalArea     = cfg['defaultArea']   as String;
    _ceilingHeight = cfg['defaultCeil']   as String;
    _floorsCount   = cfg['defaultFloors'] as String;
    _roomsCount    = cfg['defaultRooms']  as String;
  }

  Future<void> _finish() async {
    await context.read<AuthProvider>().submitSurvey(
      userType:    _userType,
      totalArea:   _toAreaValue(_totalArea),
      wallHeight:  _toCeilingValue(_ceilingHeight),
      floorsCount: _toInt(_floorsCount, '4+'),
      roomsCount:  _toInt(_roomsCount,  '6+'),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ClipRect(
               child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, anim) {
                  final isCurrent = child.key == ValueKey(_step);
                  final curve = CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeInOutCubic,
                  );
                  if (isCurrent) {
                    // Входящий: приезжает справа (вперёд) или слева (назад)
                    final begin = _isForward
                        ? const Offset(1.0, 0)
                        : const Offset(-1.0, 0);
                    return SlideTransition(
                      position: Tween<Offset>(begin: begin, end: Offset.zero)
                          .animate(curve),
                      child: child,
                    );
                  } else {
                    // Выходящий: anim идёт 1→0, begin=exitDir значит при 0 он там
                    final exitDir = _isForward
                        ? const Offset(-1.0, 0)
                        : const Offset(1.0, 0);
                    return SlideTransition(
                      position: Tween<Offset>(begin: exitDir, end: Offset.zero)
                          .animate(curve),
                      child: child,
                    );
                  }
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _buildStep(),
                      ),
                    ),
                  ),
                ),
              ),
             ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // ─── ШАПКА ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'АРТхаус',
                style: AppTextStyle.gropled(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.backgroundColor,
                ),
              ),
              // Анимированные точки-индикаторы
              Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i + 1 == _step;
                  final done   = i + 1 < _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(left: 6),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (active || done)
                          ? AppTheme.backgroundColor
                          : AppTheme.backgroundColor.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppText(
            _stepLabels[_step - 1].toUpperCase(),
            style: AppTextStyle.gropled(
              fontSize: 12,
              letterSpacing: 1.2,
              color: AppTheme.backgroundColor.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: _step / _totalSteps),
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 3,
                backgroundColor: AppTheme.backgroundColor.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(AppTheme.accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── НИЖНЯЯ ПАНЕЛЬ ────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    final isLast = _step == _totalSteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1)
            GestureDetector(
              onTap: _back,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.backgroundColor.withOpacity(0.35),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppText(
                  '← Назад',
                  style: AppTextStyle.gropled(
                    fontSize: 17,
                    color: AppTheme.backgroundColor,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 80),

          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              final enabled = _canProceed && !auth.isLoading;
              return GestureDetector(
                onTap: enabled ? _next : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                    color: enabled
                        ? (isLast ? AppTheme.accentColor : AppTheme.backgroundColor)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: auth.isLoading && isLast
                      ? const SizedBox(
                          width: 30,
                          height: 20,
                          child: BarLoader(
                            color: Colors.white,
                            barWidth: 3,
                            baseHeight: 12,
                            tallHeight: 18,
                            gap: 4,
                            inactiveOpacity: 0.5,
                          ),
                        )
                      : AppText(
                          _isSkippable
                              ? 'Пропустить →'
                            : (isLast ? 'Начать →' : 'Продолжить →'),
                          style: AppTextStyle.gropled(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? (isLast ? Colors.white : AppTheme.textPrimary)
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── РОУТЕР ШАГОВ ─────────────────────────────────────────────────────────

  Widget _buildStep() => switch (_step) {
    1 => _step1(),
    2 => _step2Details(),
    3 => _step3(),
    4 => _step4(),
    5 => _step5(),
    _ => const SizedBox(),
  };

  // ─── ЗАГОЛОВОК ШАГА ───────────────────────────────────────────────────────

  Widget _stepTitle(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      AppText(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyle.gropled(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppTheme.backgroundColor,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 10),
      AppText(
        sub,
        textAlign: TextAlign.center,
        style: AppTextStyle.gropled(
          fontSize: 17,
          color: AppTheme.backgroundColor.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 32),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ШАГ 1 — Тип помещения
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Где вы чувствуете\nсебя дома?',
          'Расскажите — мы подберём шаблон именно для вас',
        ),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: _premiseOptions.map((opt) {
            final sel = _premiseType == opt['id'];
            return GestureDetector(
              onTap: () => setState(() {
                _premiseType = opt['id'] as String;
                _userType = (opt['id'] == 'office' || opt['id'] == 'commerce')
                    ? UserType.b2b
                    : UserType.b2c;
                _applyConfig(_premiseType!);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                width: 118,
                height: 118,
                transform: Matrix4.identity()..scale(sel ? 1.07 : 1.0),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.backgroundColor
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sel
                        ? AppTheme.backgroundColor
                        : AppTheme.backgroundColor.withOpacity(0.22),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      size: 38,
                      color: sel ? AppTheme.primaryColor : _iconColor,
                    ),
                    const SizedBox(height: 10),
                    AppText(
                      opt['label']! as String,
                      style: AppTextStyle.gropled(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ШАГ 2 — Ещё пара деталей
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _step2Details() {
    final cfg = _premiseType != null ? _premiseConfigs[_premiseType!]! : null;

    if (cfg == null) {
      return Column(
        children: [
          _stepTitle(
            'Сначала выберите\nтип помещения',
            'Вернитесь назад и укажите пространство',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Немного о вашем\nпространстве',
          'Не переживайте о точности — всегда можно уточнить',
        ),
        _optionsGroup(
          label: cfg['areaLabel'] as String,
          value: _totalArea,
          options: (cfg['area'] as List).cast<String>(),
          onChanged: (v) => setState(() => _totalArea = v),
        ),
        const SizedBox(height: 18),
        _optionsGroup(
          label: cfg['ceilLabel'] as String,
          value: _ceilingHeight,
          options: (cfg['ceil'] as List).cast<String>(),
          onChanged: (v) => setState(() => _ceilingHeight = v),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _optionsGroup(
                label: cfg['floorsLabel'] as String,
                value: _floorsCount,
                options: (cfg['floors'] as List).cast<String>(),
                onChanged: (v) => setState(() => _floorsCount = v),
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _optionsGroup(
                label: cfg['roomsLabel'] as String,
                value: _roomsCount,
                options: (cfg['rooms'] as List).cast<String>(),
                onChanged: (v) => setState(() => _roomsCount = v),
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ШАГ 3 — Приоритеты
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _step3() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _stepTitle(
        'Что делает дом\nнастоящим домом?',
        'Выберите всё что откликается — настроим советы под вас',
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _priorities.map((p) {
          final label = p['label']!;
          final emoji = p['emoji']!;
          final sel   = _selectedPriorities.contains(label);
          return GestureDetector(
            onTap: () => setState(() => sel
                ? _selectedPriorities.remove(label)
                : _selectedPriorities.add(label)),
            child: _chip('$emoji  $label', sel),
          );
        }).toList(),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ШАГ 4 — Проблемные зоны (необязательный)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _step4() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _stepTitle(
        'Есть что-то,\nчто хочется изменить?',
        'Пропустите если пока всё ок — вернёмся к этому позже',
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _problemZones.map((p) {
          final label = p['label']!;
          final emoji = p['emoji']!;
          final sel   = _selectedProblems.contains(label);
          return GestureDetector(
            onTap: () => setState(() => sel
                ? _selectedProblems.remove(label)
                : _selectedProblems.add(label)),
            child: _chip('$emoji  $label', sel),
          );
        }).toList(),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _otherCtrl,
        style: const TextStyle(
          fontFamily: AppTextStyle.fontFamily,
          fontSize: 17,
          color: AppTheme.backgroundColor,
        ),
        cursorColor: AppTheme.backgroundColor,
        decoration: InputDecoration(
          hintText: 'Или напишите своими словами...',
          hintStyle: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontSize: 17,
            color: AppTheme.backgroundColor.withOpacity(0.38),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppTheme.backgroundColor.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppTheme.backgroundColor.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: AppTheme.backgroundColor, width: 1.5),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ШАГ 5 — Стиль интерьера
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _step5() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _stepTitle(
        'Какая атмосфера\nвам по душе?',
        'Выберите несколько — или попросите нас помочь с выбором',
      ),
      Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: _styles.map((s) {
          final id    = s['id']!;
          final label = s['label']!;
          final sub   = s['sub']!;
          final emoji = s['emoji']!;
          final sel   = _interiorStyles.contains(id);
          return GestureDetector(
            onTap: () => setState(() =>
                sel ? _interiorStyles.remove(id) : _interiorStyles.add(id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              width: 146,
              padding: const EdgeInsets.all(14),
              transform: Matrix4.identity()..scale(sel ? 1.05 : 1.0),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.backgroundColor
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: sel
                      ? AppTheme.backgroundColor
                      : AppTheme.backgroundColor.withOpacity(0.22),
                  width: sel ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryColor.withOpacity(0.15)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 34,
                        fontFamily: 'Segoe UI Emoji',
                        fontFamilyFallback: [
                          'Apple Color Emoji',
                          'Noto Color Emoji',
                          'Android Emoji',
                          'EmojiSymbols',
                        ],
                        inherit: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    label,
                    style: AppTextStyle.gropled(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    sub,
                    style: AppTextStyle.gropled(
                      fontSize: 12,
                      color: sel
                          ? AppTheme.primaryColor.withOpacity(0.7)
                          : AppTheme.backgroundColor.withOpacity(0.55),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      Consumer<AuthProvider>(
        builder: (_, auth, __) => auth.error != null
            ? Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppText(
                          auth.error!,
                          style: AppTextStyle.gropled(
                            fontSize: 14,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );

  // ─── ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ──────────────────────────────────────────────

  Widget _optionsGroup({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.gropled(
            fontSize: compact ? 16 : 18,
            color: AppTheme.backgroundColor.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: options.map((o) {
            final sel = o == value;
            return GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 14,
                  vertical: 9,
                ),
                transform: Matrix4.identity()..scale(sel ? 1.04 : 1.0),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.backgroundColor
                        .withOpacity(sel ? 1.0 : 0.3),
                    width: 1.5,
                  ),
                ),
                child: AppText(
                  o,
                  style: AppTextStyle.gropled(
                    fontSize: compact ? 14 : 15,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _chip(String label, bool sel) {
    final parts = label.split(RegExp(r'\s{2,}'));
    final hasEmoji = parts.length > 1;
    final emoji = hasEmoji ? parts.first : null;
    final text = hasEmoji ? parts.sublist(1).join('  ') : label;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: sel ? 1.0 : 0.72,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(2),
        padding: EdgeInsets.symmetric(
          horizontal: sel ? 20 : 18,
          vertical: sel ? 13 : 12,
        ),
        decoration: BoxDecoration(
          color: sel ? AppTheme.backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.backgroundColor.withOpacity(sel ? 1.0 : 0.35),
            width: sel ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Segoe UI Emoji',
                  fontFamilyFallback: [
                    'Apple Color Emoji',
                    'Noto Color Emoji',
                    'Android Emoji',
                    'EmojiSymbols',
                  ],
                  // Отключаем наследование цвета, чтобы эмодзи были цветными
                  inherit: false,
                ),
              ),
              const SizedBox(width: 8),
            ],
            AppText(
              text,
              style: AppTextStyle.gropled(
                fontSize: 15,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
