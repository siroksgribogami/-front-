import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/bar_loader.dart';
import '../../core/theme/brand_ui.dart';
import '../../data/premise_rooms_catalog.dart';
import '../../models/onboarding_survey.dart';
import '../../providers/auth_provider.dart';

/// Опрос после регистрации (3 шага). Роль берётся с экрана регистрации.
class PostRegisterSurveyScreen extends StatefulWidget {
  const PostRegisterSurveyScreen({super.key});

  @override
  State<PostRegisterSurveyScreen> createState() =>
      _PostRegisterSurveyScreenState();
}

class _PostRegisterSurveyScreenState extends State<PostRegisterSurveyScreen> {
  int _step = 1;
  bool _isForward = true;

  /// Роль уже выбрана на экране регистрации — в опросе не спрашиваем повторно.
  OnboardingRole? _role;

  int get _totalSteps =>
      _role == OnboardingRole.customer ? 5 : 3;

  // ——— Заказчик ———
  final Set<String> _workCategoryIds = {};
  String? _premiseKind;
  /// Этажность/уровни объекта (квартира, дом, офис) — необязательно.
  String? _floors;
  /// Примерная площадь — выбор диапазона, без ручного ввода цифр.
  String? _areaRangeId;
  String? _timelineId;
  final _customerCityCtrl = TextEditingController();
  /// Каталог типовых комнат для выбранного типа объекта.
  final List<({String id, String label})> _roomCatalog = [];
  final Set<String> _selectedRoomIds = {};

  // ——— Мастер ———
  final Set<String> _specIds = {};
  String? _experienceId;
  final _cityCtrl = TextEditingController();

  static const _serviceLines = <Map<String, String>>[
    {'id': 'repair', 'label': 'Ремонт', 'emoji': '🔧'},
    {'id': 'design', 'label': 'Дизайн интерьера', 'emoji': '🎨'},
    {'id': 'cleaning', 'label': 'Клининг', 'emoji': '🧹'},
    {'id': 'furniture', 'label': 'Сборка мебели', 'emoji': '🪛'},
    {'id': 'electrical', 'label': 'Электрика', 'emoji': '⚡'},
    {'id': 'plumbing', 'label': 'Сантехника', 'emoji': '🚿'},
    {'id': 'other', 'label': 'Другое', 'emoji': '✏️'},
  ];

  static const _premises = <Map<String, String>>[
    {'id': 'apartment', 'label': 'Квартира'},
    {'id': 'house', 'label': 'Дом'},
    {'id': 'office', 'label': 'Офис'},
  ];

  static const _timelines = <Map<String, String>>[
    {'id': 'urgent', 'label': 'Срочно'},
    {'id': 'within_month', 'label': 'В течение месяца'},
    {'id': 'browsing', 'label': 'Просто смотрю пока'},
  ];

  /// Диапазоны площади (без ручного ввода). id совпадает с `_approxAreaSqm`.
  static const _areaRanges = <Map<String, String>>[
    {'id': 'area_xs', 'label': 'До 40 м²'},
    {'id': 'area_s', 'label': '40–60 м²'},
    {'id': 'area_m', 'label': '60–90 м²'},
    {'id': 'area_l', 'label': '90–130 м²'},
    {'id': 'area_xl', 'label': 'Больше 130 м²'},
    {'id': 'area_unknown', 'label': 'Пока не знаю'},
  ];

  /// Вопрос об этажности зависит от типа объекта.
  String get _floorsQuestion => switch (_premiseKind) {
        'apartment' => 'Сколько уровней в квартире?',
        'office' => 'Сколько этажей занимает офис?',
        _ => 'Сколько этажей в доме?',
      };

  /// Варианты этажности: для квартиры — «уровни», иначе — «этажи».
  List<({String id, String label})> get _floorOptions {
    final apt = _premiseKind == 'apartment';
    return [
      (id: '1', label: apt ? '1 уровень' : '1 этаж'),
      (id: '2', label: apt ? '2 уровня' : '2 этажа'),
      (id: '3', label: apt ? '3 уровня' : '3 этажа'),
      (id: '4+', label: '4 и больше'),
    ];
  }

  static const _experience = <Map<String, String>>[
    {'id': 'lt1', 'label': 'Меньше года'},
    {'id': 'y1_3', 'label': '1–3 года'},
    {'id': 'y3_5', 'label': '3–5 лет'},
    {'id': 'gt5', 'label': 'Больше 5 лет'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fromReg = context.read<AuthProvider>().registeredOnboardingRole;
      if (fromReg != null && _role != fromReg) {
        setState(() {
          _role = fromReg;
          _resetBranchState();
        });
      }
    });
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _customerCityCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_role == null) return false;
    switch (_step) {
      case 1:
        if (_role == OnboardingRole.customer) return _workCategoryIds.isNotEmpty;
        return _specIds.isNotEmpty;
      case 2:
        if (_role == OnboardingRole.customer) {
          // Этажность и площадь — необязательны; нужен только тип объекта.
          return _premiseKind != null;
        }
        return _experienceId != null;
      case 3:
        if (_role == OnboardingRole.customer) return _selectedRoomIds.isNotEmpty;
        return _cityCtrl.text.trim().length >= 2;
      case 4:
        if (_role == OnboardingRole.customer) {
          return _customerCityCtrl.text.trim().length >= 2;
        }
        return false;
      case 5:
        if (_role == OnboardingRole.customer) return _timelineId != null;
        return false;
      default:
        return false;
    }
  }

  /// Выбранные комнаты — только id + название. Точные размеры пользователь
  /// потом задаёт в рисовальщике карты, в опросе цифры не спрашиваем.
  List<Map<String, dynamic>> get _roomsDetailPayload {
    return _roomCatalog
        .where((r) => _selectedRoomIds.contains(r.id))
        .map((r) => <String, dynamic>{'id': r.id, 'label': r.label})
        .toList();
  }

  void _next() {
    if (_step < _totalSteps) {
      setState(() {
        _isForward = true;
        _step++;
        if (_role == OnboardingRole.customer &&
            _step == 3 &&
            _premiseKind != null) {
          _syncRoomCatalog(_premiseKind!);
        }
      });
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() {
        _isForward = false;
        _step--;
      });
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    bool ok = false;
    if (_role == OnboardingRole.customer) {
      ok = await auth.submitSurvey(
        role: OnboardingRole.customer,
        workCategoryIds: _workCategoryIds.toList(),
        premiseKind: _premiseKind,
        houseFloors: _floors,
        areaApproxId:
            _areaRangeId == 'area_unknown' ? null : _areaRangeId,
        roomsDetail: _roomsDetailPayload,
        city: _customerCityCtrl.text,
        startTimelineId: _timelineId,
      );
    } else if (_role == OnboardingRole.master) {
      ok = await auth.submitSurvey(
        role: OnboardingRole.master,
        specializationIds: _specIds.toList(),
        experienceId: _experienceId,
        city: _cityCtrl.text,
      );
    }
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'Не удалось сохранить ответы'),
      ),
    );
  }

  String get _roleKickerLabel => _role == OnboardingRole.customer
      ? 'Опрос · Заказчик'
      : 'Опрос · Мастер';

  String get _headerTitle {
    if (_role == OnboardingRole.customer) {
      return switch (_step) {
        1 => 'Что вам нужно\nсделать?',
        2 => 'Опишите ваше\nпространство',
        3 => 'Какие комнаты\nу вас есть?',
        4 => 'Откуда вы?',
        5 => 'Когда планируете\nначать?',
        _ => '',
      };
    }
    return switch (_step) {
      1 => 'Ваша\nспециализация',
      2 => 'Опыт работы',
      3 => 'В каком городе\nработаете?',
      _ => '',
    };
  }

  String? get _headerSubtitle {
    if (_role == OnboardingRole.customer) {
      return switch (_step) {
        1 => 'Можно выбрать несколько категорий',
        2 => 'Тип объекта и примерная площадь',
        3 => 'Просто отметьте — размеры зададите позже на карте',
        4 => 'Укажите город — подберём мастеров и цены в вашем регионе',
        5 => 'Можно изменить позже в профиле',
        _ => null,
      };
    }
    return switch (_step) {
      1 => 'Можно выбрать несколько направлений',
      2 => 'Честный ответ поможет подобрать подходящие заказы',
      3 => 'Укажите город или регион — так клиенты смогут вас находить',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: Column(
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
                    final begin = _isForward
                        ? const Offset(1.0, 0)
                        : const Offset(-1.0, 0);
                    return SlideTransition(
                      position: Tween<Offset>(begin: begin, end: Offset.zero)
                          .animate(curve),
                      child: child,
                    );
                  } else {
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
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
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
    );
  }

  Widget _buildHeader() {
    return ColoredBox(
      color: BrandRuntime.needles,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -1),
                  radius: 1.2,
                  colors: [
                    BrandColors.needlesLight.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BrandSteps(
                          total: _totalSteps,
                          active: _step,
                          onDark: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '$_step / $_totalSteps',
                        style: BrandUi.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.onNeedles.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  BrandKicker(
                    _roleKickerLabel,
                    onDark: true,
                    color: BrandColors.dawn,
                    fontSize: 10.5,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _headerTitle,
                    style: pochaevsk(
                      fontSize: 30,
                      color: BrandColors.onNeedles,
                      height: 1.04,
                    ),
                  ),
                  if (_headerSubtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _headerSubtitle!,
                      style: BrandUi.inter(
                        fontSize: 14,
                        color: BrandColors.onNeedles.withOpacity(0.72),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    final isLast = _step == _totalSteps;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        16,
        22,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          if (_step > 1)
            BrandGhostButton(label: 'Назад', onPressed: _back)
          else
            const SizedBox.shrink(),
          if (_step > 1) const SizedBox(width: 12),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                final enabled = _canProceed && !auth.isLoading;
                if (auth.isLoading && isLast) {
                  return Center(
                    child: SizedBox(
                      width: 30,
                      height: 20,
                      child: BarLoader(
                        color: BrandRuntime.needles,
                        barWidth: 3,
                        baseHeight: 12,
                        tallHeight: 18,
                        gap: 4,
                        inactiveOpacity: 0.5,
                      ),
                    ),
                  );
                }
                return BrandPrimaryButton(
                  label: isLast ? 'Начать' : 'Далее',
                  onPressed: enabled ? _next : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    if (_role == null) {
      return Center(
        child: Text(
          'Не удалось определить роль.\nЗавершите регистрацию заново.',
          textAlign: TextAlign.center,
          style: BrandUi.inter(
            fontSize: 16,
            color: BrandRuntime.ink.withOpacity(0.75),
          ),
        ),
      );
    }
    switch (_step) {
      case 1:
        return _role == OnboardingRole.customer
            ? _stepCustomerWork()
            : _stepMasterSpec();
      case 2:
        return _role == OnboardingRole.customer
            ? _stepCustomerSpace()
            : _stepMasterExperience();
      case 3:
        return _role == OnboardingRole.customer
            ? _stepCustomerRooms()
            : _stepMasterCity();
      case 4:
        return _role == OnboardingRole.customer
            ? _stepCustomerCity()
            : const SizedBox();
      case 5:
        return _stepCustomerWhen();
      default:
        return const SizedBox();
    }
  }

  void _resetBranchState() {
    _workCategoryIds.clear();
    _premiseKind = null;
    _floors = null;
    _areaRangeId = null;
    _timelineId = null;
    _customerCityCtrl.clear();
    _clearRoomCatalog();
    _specIds.clear();
    _experienceId = null;
    _cityCtrl.clear();
  }

  void _clearRoomCatalog() {
    _roomCatalog.clear();
    _selectedRoomIds.clear();
  }

  void _syncRoomCatalog(String premiseKind) {
    if (_roomCatalog.isNotEmpty) return;
    final labels = PremiseRoomsCatalog.suggestedRoomLabels(premiseKind);
    final mapRooms = PremiseRoomsCatalog.roomsForMap(premiseKind);
    for (var i = 0; i < labels.length; i++) {
      final id = mapRooms[i]['id'] as String;
      _roomCatalog.add((id: id, label: labels[i]));
    }
  }

  // ─── Заказчик: задача ─────────────────────────────────────────────────────
  Widget _stepCustomerWork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Вид работ',
          style: BrandUi.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.ink.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _serviceLines.map((m) {
            final id = m['id']!;
            final label = m['label']!;
            final sel = _workCategoryIds.contains(id);
            return BrandChip(
              label: label,
              selected: sel,
              onTap: () => setState(() {
                if (sel) {
                  _workCategoryIds.remove(id);
                } else {
                  _workCategoryIds.add(id);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Заказчик: пространство ───────────────────────────────────────────────
  Widget _stepCustomerSpace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип помещения',
          style: BrandUi.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.ink.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _premises.map((p) {
            final id = p['id']!;
            final label = p['label']!;
            final sel = _premiseKind == id;
            return BrandChip(
              label: label,
              selected: sel,
              onTap: () => setState(() {
                if (_premiseKind != id) {
                  _clearRoomCatalog();
                }
                _premiseKind = id;
              }),
            );
          }).toList(),
        ),
        if (_premiseKind != null) ...[
          const SizedBox(height: 26),
          Text(
            _floorsQuestion,
            style: BrandUi.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrandRuntime.ink.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _floorOptions.map((f) {
              final sel = _floors == f.id;
              return BrandChip(
                label: f.label,
                selected: sel,
                onTap: () => setState(() => _floors = f.id),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 26),
        Text(
          'Примерная площадь',
          style: BrandUi.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.ink.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _areaRanges.map((a) {
            final id = a['id']!;
            final label = a['label']!;
            final sel = _areaRangeId == id;
            return BrandChip(
              label: label,
              selected: sel,
              onTap: () => setState(() => _areaRangeId = id),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Заказчик: какие помещения (только выбор, без размеров) ───────────────
  Widget _stepCustomerRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Какие помещения',
          style: BrandUi.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.ink.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _roomCatalog.map((room) {
            final sel = _selectedRoomIds.contains(room.id);
            return BrandChip(
              label: room.label,
              selected: sel,
              onTap: () => setState(() {
                if (sel) {
                  _selectedRoomIds.remove(room.id);
                } else {
                  _selectedRoomIds.add(room.id);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.draw_outlined,
                size: 18, color: BrandRuntime.ink.withOpacity(0.4)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Точные размеры и форму комнат зададите потом на карте — '
                'нарисуете план пальцем.',
                style: BrandUi.inter(
                  fontSize: 12.5,
                  color: BrandRuntime.ink.withOpacity(0.5),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _surveyTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textAlign: TextAlign.start,
      style: BrandUi.inter(fontSize: 15, color: BrandRuntime.ink),
      cursorColor: BrandRuntime.needles,
      decoration: BrandUi.inputDecoration(hint: hint),
    );
  }

  // ─── Заказчик: город ──────────────────────────────────────────────────────
  Widget _stepCustomerCity() {
    return _surveyTextField(
      controller: _customerCityCtrl,
      hint: 'Например: Москва',
      onChanged: (_) => setState(() {}),
    );
  }

  // ─── Заказчик: срок ───────────────────────────────────────────────────────
  Widget _stepCustomerWhen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._timelines.map((t) {
          final id = t['id']!;
          final label = t['label']!;
          final sel = _timelineId == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _timelineId = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: sel ? BrandRuntime.card : BrandRuntime.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? BrandRuntime.needles : BrandRuntime.border,
                    width: sel ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: BrandUi.inter(
                    fontSize: 15,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? BrandRuntime.needles : BrandRuntime.ink,
                  ),
                ),
              ),
            ),
          );
        }),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => auth.error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BrandColors.surik.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: BrandColors.surik.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: BrandColors.surik, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.error!,
                            style: BrandUi.inter(
                              fontSize: 14,
                              color: BrandColors.surik,
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
  }

  // ─── Мастер: специализация ────────────────────────────────────────────────
  Widget _stepMasterSpec() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Направления',
          style: BrandUi.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.ink.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _serviceLines.map((m) {
            final id = m['id']!;
            final label = m['label']!;
            final sel = _specIds.contains(id);
            return BrandChip(
              label: label,
              selected: sel,
              onTap: () => setState(() {
                if (sel) {
                  _specIds.remove(id);
                } else {
                  _specIds.add(id);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Мастер: опыт ─────────────────────────────────────────────────────────
  Widget _stepMasterExperience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._experience.map((e) {
          final id = e['id']!;
          final label = e['label']!;
          final sel = _experienceId == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _experienceId = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: sel ? BrandRuntime.card : BrandRuntime.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? BrandRuntime.needles : BrandRuntime.border,
                    width: sel ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: BrandUi.inter(
                    fontSize: 15,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? BrandRuntime.needles : BrandRuntime.ink,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Мастер: город ────────────────────────────────────────────────────────
  Widget _stepMasterCity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _surveyTextField(
          controller: _cityCtrl,
          hint: 'Например: Москва',
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => auth.error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BrandColors.surik.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: BrandColors.surik.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: BrandColors.surik, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.error!,
                            style: BrandUi.inter(
                              fontSize: 14,
                              color: BrandColors.surik,
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
  }
}
