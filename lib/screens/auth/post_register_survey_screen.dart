import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/bar_loader.dart';
import '../../core/theme/app_text_style.dart';
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

class _RoomFieldState {
  _RoomFieldState({required this.id, required this.label});

  final String id;
  final String label;
  bool selected = false;
  final TextEditingController areaCtrl = TextEditingController();
  final TextEditingController lengthCtrl = TextEditingController();
  final TextEditingController widthCtrl = TextEditingController();

  void dispose() {
    areaCtrl.dispose();
    lengthCtrl.dispose();
    widthCtrl.dispose();
  }
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
  String? _houseFloors;
  final _totalAreaCtrl = TextEditingController();
  String? _timelineId;
  final _customerCityCtrl = TextEditingController();
  final Map<String, _RoomFieldState> _roomsById = {};

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

  static const _houseFloorOptions = <Map<String, String>>[
    {'id': '1', 'label': '1 этаж'},
    {'id': '2', 'label': '2 этажа'},
    {'id': '3', 'label': '3 этажа'},
    {'id': '4+', 'label': '4 и больше'},
  ];

  static const _experience = <Map<String, String>>[
    {'id': 'lt1', 'label': 'Меньше года'},
    {'id': 'y1_3', 'label': '1–3 года'},
    {'id': 'y3_5', 'label': '3–5 лет'},
    {'id': 'gt5', 'label': 'Больше 5 лет'},
  ];

  List<String> get _stepSubtitles {
    if (_role == OnboardingRole.customer) {
      return ['Задача', 'Пространство', 'Комнаты', 'Город', 'Срок'];
    }
    return ['Специализация', 'Опыт', 'Город'];
  }

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
    _totalAreaCtrl.dispose();
    _customerCityCtrl.dispose();
    for (final room in _roomsById.values) {
      room.dispose();
    }
    super.dispose();
  }

  double? get _parsedTotalArea {
    final raw = _totalAreaCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  bool get _canProceed {
    if (_role == null) return false;
    switch (_step) {
      case 1:
        if (_role == OnboardingRole.customer) return _workCategoryIds.isNotEmpty;
        return _specIds.isNotEmpty;
      case 2:
        if (_role == OnboardingRole.customer) {
          final area = _parsedTotalArea;
          final baseOk =
              _premiseKind != null && area != null && area > 0 && area <= 2000;
          if (_premiseKind == 'house') {
            return baseOk && _houseFloors != null;
          }
          return baseOk;
        }
        return _experienceId != null;
      case 3:
        if (_role == OnboardingRole.customer) return _roomsSelectionValid;
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

  bool get _roomsSelectionValid {
    final selected = _roomsById.values.where((r) => r.selected);
    if (selected.isEmpty) return false;
    return selected.every((r) {
      final area = double.tryParse(
        r.areaCtrl.text.trim().replaceAll(',', '.'),
      );
      return area != null && area > 0;
    });
  }

  List<Map<String, dynamic>> get _roomsDetailPayload {
    return _roomsById.values
        .where((r) => r.selected)
        .map((r) {
          final area = double.parse(
            r.areaCtrl.text.trim().replaceAll(',', '.'),
          );
          final len = double.tryParse(
            r.lengthCtrl.text.trim().replaceAll(',', '.'),
          );
          final wid = double.tryParse(
            r.widthCtrl.text.trim().replaceAll(',', '.'),
          );
          return <String, dynamic>{
            'id': r.id,
            'label': r.label,
            'area_sqm': area,
            if (len != null && len > 0) 'length_m': len,
            if (wid != null && wid > 0) 'width_m': wid,
          };
        })
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
        houseFloors: _houseFloors,
        totalAreaSqm: _parsedTotalArea,
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
              Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i + 1 == _step;
                  final done = i + 1 < _step;
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
            _stepSubtitles[_step - 1].toUpperCase(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                    color: enabled
                        ? (isLast
                            ? AppTheme.accentColor
                            : AppTheme.backgroundColor)
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
                          isLast ? 'Начать →' : 'Продолжить →',
                          style: AppTextStyle.gropled(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? (isLast
                                    ? Colors.white
                                    : AppTheme.textPrimary)
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

  Widget _buildStep() {
    if (_role == null) {
      return Center(
        child: AppText(
          'Не удалось определить роль.\nЗавершите регистрацию заново.',
          textAlign: TextAlign.center,
          style: AppTextStyle.gropled(
            fontSize: 16,
            color: AppTheme.backgroundColor.withOpacity(0.85),
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

  Widget _stepTitle(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.gropled(
              fontSize: 32,
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
          const SizedBox(height: 28),
        ],
      );

  void _resetBranchState() {
    _workCategoryIds.clear();
    _premiseKind = null;
    _houseFloors = null;
    _totalAreaCtrl.clear();
    _timelineId = null;
    _customerCityCtrl.clear();
    _clearRoomCatalog();
    _specIds.clear();
    _experienceId = null;
    _cityCtrl.clear();
  }

  void _clearRoomCatalog() {
    for (final room in _roomsById.values) {
      room.dispose();
    }
    _roomsById.clear();
  }

  void _syncRoomCatalog(String premiseKind) {
    if (_roomsById.isNotEmpty) return;
    final labels = PremiseRoomsCatalog.suggestedRoomLabels(premiseKind);
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final id = PremiseRoomsCatalog.roomsForMap(premiseKind)[i]['id'] as String;
      _roomsById[id] = _RoomFieldState(id: id, label: label);
    }
  }

  // ─── Заказчик: задача ─────────────────────────────────────────────────────
  Widget _stepCustomerWork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle(
          'Что вам нужно\nсделать?',
          'Можно выбрать несколько категорий',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final itemWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _serviceLines.map((m) {
                final id = m['id']!;
                final label = '${m['emoji']}  ${m['label']}';
                final sel = _workCategoryIds.contains(id);
                return SizedBox(
                  width: itemWidth,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (sel) {
                        _workCategoryIds.remove(id);
                      } else {
                        _workCategoryIds.add(id);
                      }
                    }),
                    child: _chip(label, sel),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ─── Заказчик: пространство ───────────────────────────────────────────────
  Widget _stepCustomerSpace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Опишите ваше\nпространство',
          'Тип объекта и общая площадь',
        ),
        AppText(
          'Тип помещения',
          style: AppTextStyle.gropled(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.backgroundColor.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _premises.map((p) {
            final id = p['id']!;
            final label = p['label']!;
            final sel = _premiseKind == id;
            return GestureDetector(
              onTap: () => setState(() {
                if (_premiseKind != id) {
                  _clearRoomCatalog();
                }
                _premiseKind = id;
                if (id != 'house') _houseFloors = null;
              }),
              child: _compactChip(label, sel),
            );
          }).toList(),
        ),
        if (_premiseKind == 'house') ...[
          const SizedBox(height: 22),
          AppText(
            'Сколько этажей в доме?',
            style: AppTextStyle.gropled(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.backgroundColor.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _houseFloorOptions.map((f) {
              final id = f['id']!;
              final label = f['label']!;
              final sel = _houseFloors == id;
              return GestureDetector(
                onTap: () => setState(() => _houseFloors = id),
                child: _compactChip(label, sel),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 22),
        AppText(
          'Общая площадь, м²',
          style: AppTextStyle.gropled(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.backgroundColor.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 10),
        _surveyTextField(
          controller: _totalAreaCtrl,
          hint: 'Например: 62',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ─── Заказчик: комнаты и размеры ────────────────────────────────────────
  Widget _stepCustomerRooms() {
    final rooms = _roomsById.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Какие комнаты\nу вас есть?',
          'Отметьте помещения и укажите примерные размеры',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rooms.map((room) {
            final sel = room.selected;
            return GestureDetector(
              onTap: () => setState(() => room.selected = !room.selected),
              child: _compactChip(room.label, sel),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        ...rooms.where((r) => r.selected).map(_roomSizeFields),
      ],
    );
  }

  Widget _roomSizeFields(_RoomFieldState room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            room.label,
            style: AppTextStyle.gropled(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.backgroundColor,
            ),
          ),
          const SizedBox(height: 8),
          _surveyTextField(
            controller: room.areaCtrl,
            hint: 'Площадь, м²',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _surveyTextField(
                  controller: room.lengthCtrl,
                  hint: 'Длина, м (необяз.)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _surveyTextField(
                  controller: room.widthCtrl,
                  hint: 'Ширина, м (необяз.)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _surveyTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textAlign: TextAlign.start,
      style: const TextStyle(
        fontFamily: AppTextStyle.fontFamily,
        fontSize: 17,
        color: AppTheme.backgroundColor,
      ),
      cursorColor: AppTheme.backgroundColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppTextStyle.fontFamily,
          fontSize: 16,
          color: AppTheme.backgroundColor.withOpacity(0.38),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.backgroundColor.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.backgroundColor.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.backgroundColor, width: 1.5),
        ),
      ),
    );
  }

  // ─── Заказчик: город ──────────────────────────────────────────────────────
  Widget _stepCustomerCity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Откуда вы?',
          'Укажите город — подберём мастеров и цены в вашем регионе',
        ),
        _surveyTextField(
          controller: _customerCityCtrl,
          hint: 'Например: Москва',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ─── Заказчик: срок ───────────────────────────────────────────────────────
  Widget _stepCustomerWhen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Когда планируете\nначать?',
          'Можно изменить позже в профиле',
        ),
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
                  color: sel ? AppTheme.backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.backgroundColor.withOpacity(sel ? 1 : 0.35),
                    width: sel ? 2 : 1.5,
                  ),
                ),
                child: AppText(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.gropled(
                    fontSize: 17,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
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
  }

  // ─── Мастер: специализация ────────────────────────────────────────────────
  Widget _stepMasterSpec() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Ваша\nспециализация',
          'Можно выбрать несколько направлений',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _serviceLines.map((m) {
            final id = m['id']!;
            final label = '${m['emoji']}  ${m['label']}';
            final sel = _specIds.contains(id);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _specIds.remove(id);
                } else {
                  _specIds.add(id);
                }
              }),
              child: _chip(label, sel),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Мастер: опыт ─────────────────────────────────────────────────────────
  Widget _stepMasterExperience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Опыт работы',
          'Честный ответ поможет подобрать подходящие заказы',
        ),
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
                  color: sel ? AppTheme.backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.backgroundColor.withOpacity(sel ? 1 : 0.35),
                    width: sel ? 2 : 1.5,
                  ),
                ),
                child: AppText(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.gropled(
                    fontSize: 17,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'В каком городе\nработаете?',
          'Укажите город или регион — так клиенты смогут вас находить',
        ),
        TextField(
          controller: _cityCtrl,
          onChanged: (_) => setState(() {}),
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontSize: 17,
            color: AppTheme.backgroundColor,
          ),
          cursorColor: AppTheme.backgroundColor,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Например: Москва',
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
        ),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => auth.error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
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
  }

  Widget _chip(String label, bool sel) {
    final parts = label.split(RegExp(r'\s{2,}'));
    final emoji = parts.length > 1 ? parts.first : null;
    final text = parts.length > 1 ? parts.sublist(1).join('  ') : label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: sel ? AppTheme.backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.backgroundColor.withOpacity(sel ? 1 : 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 20, inherit: false)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: AppText(
              text,
              style: AppTextStyle.gropled(
                fontSize: 15,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactChip(String label, bool sel) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: sel ? AppTheme.backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.backgroundColor.withOpacity(sel ? 1 : 0.35),
          width: sel ? 2 : 1.5,
        ),
      ),
      child: AppText(
        label,
        style: AppTextStyle.gropled(
          fontSize: 15,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          color: sel ? AppTheme.primaryColor : AppTheme.backgroundColor,
        ),
      ),
    );
  }
}
