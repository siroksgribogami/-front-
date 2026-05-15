import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/bar_loader.dart';
import '../../core/theme/app_text_style.dart';
import '../../models/onboarding_survey.dart';
import '../../providers/auth_provider.dart';

/// Опрос после регистрации: заказчик или мастер, затем разветвление шагов.
class PostRegisterSurveyScreen extends StatefulWidget {
  const PostRegisterSurveyScreen({super.key});

  @override
  State<PostRegisterSurveyScreen> createState() =>
      _PostRegisterSurveyScreenState();
}

class _PostRegisterSurveyScreenState extends State<PostRegisterSurveyScreen> {
  static const int _totalSteps = 4;

  int _step = 1;
  bool _isForward = true;

  OnboardingRole? _role;

  // ——— Заказчик ———
  String? _workCategoryId;
  String? _premiseKind;
  String? _houseFloors;  // Количество этажей (только для дома)
  String? _areaId;
  String? _timelineId;

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

  static const _areas = <Map<String, String>>[
    {'id': 'area_xs', 'label': 'до 40 м²'},
    {'id': 'area_s', 'label': '40–70 м²'},
    {'id': 'area_m', 'label': '70–100 м²'},
    {'id': 'area_l', 'label': '100+ м²'},
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
    if (_role == null) {
      return ['Кто вы?', 'Шаг 2', 'Шаг 3', 'Шаг 4'];
    }
    if (_role == OnboardingRole.customer) {
      return ['Кто вы?', 'Задача', 'Пространство', 'Срок'];
    }
    return ['Кто вы?', 'Специализация', 'Опыт', 'Город'];
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_step) {
      case 1:
        return _role != null;
      case 2:
        if (_role == OnboardingRole.customer) return _workCategoryId != null;
        if (_role == OnboardingRole.master) return _specIds.isNotEmpty;
        return false;
      case 3:
        if (_role == OnboardingRole.customer) {
          final baseOk = _premiseKind != null && _areaId != null;
          // Если тип = дом, нужно также выбрать количество этажей
          if (_premiseKind == 'house') {
            return baseOk && _houseFloors != null;
          }
          return baseOk;
        }
        if (_role == OnboardingRole.master) return _experienceId != null;
        return false;
      case 4:
        if (_role == OnboardingRole.customer) return _timelineId != null;
        if (_role == OnboardingRole.master) {
          return _cityCtrl.text.trim().length >= 2;
        }
        return false;
      default:
        return false;
    }
  }

  void _next() {
    if (_step < _totalSteps) {
      setState(() {
        _isForward = true;
        _step++;
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
    if (_role == OnboardingRole.customer) {
      await auth.submitSurvey(
        role: OnboardingRole.customer,
        workCategoryId: _workCategoryId,
        premiseKind: _premiseKind,
        houseFloors: _houseFloors,  // Передаём количество этажей
        areaApproxId: _areaId,
        startTimelineId: _timelineId,
      );
    } else if (_role == OnboardingRole.master) {
      await auth.submitSurvey(
        role: OnboardingRole.master,
        specializationIds: _specIds.toList(),
        experienceId: _experienceId,
        city: _cityCtrl.text,
      );
    }
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
    switch (_step) {
      case 1:
        return _stepRole();
      case 2:
        return _role == OnboardingRole.customer
            ? _stepCustomerWork()
            : _stepMasterSpec();
      case 3:
        return _role == OnboardingRole.customer
            ? _stepCustomerSpace()
            : _stepMasterExperience();
      case 4:
        return _role == OnboardingRole.customer
            ? _stepCustomerWhen()
            : _stepMasterCity();
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

  // ─── Шаг 1 ────────────────────────────────────────────────────────────────
  Widget _stepRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Как вы планируете\nиспользовать ARThouse?',
          'От этого выбора зависят все следующие шаги',
        ),
        const SizedBox(height: 8),
        _roleCard(
          selected: _role == OnboardingRole.customer,
          emoji: '🏠',
          title: 'Я ищу мастера',
          subtitle:
              'Хочу найти специалиста для ремонта, дизайна или других работ',
          onTap: () => setState(() {
            _role = OnboardingRole.customer;
            _resetBranchState();
          }),
        ),
        const SizedBox(height: 14),
        _roleCard(
          selected: _role == OnboardingRole.master,
          emoji: '🔨',
          title: 'Я мастер',
          subtitle: 'Хочу находить заказы и клиентов',
          onTap: () => setState(() {
            _role = OnboardingRole.master;
            _resetBranchState();
          }),
        ),
      ],
    );
  }

  void _resetBranchState() {
    _workCategoryId = null;
    _premiseKind = null;
    _houseFloors = null;
    _areaId = null;
    _timelineId = null;
    _specIds.clear();
    _experienceId = null;
    _cityCtrl.clear();
  }

  Widget _roleCard({
    required bool selected,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppTheme.backgroundColor : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppTheme.backgroundColor
                : AppTheme.backgroundColor.withOpacity(0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36, inherit: false),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: AppTextStyle.gropled(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.backgroundColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    subtitle,
                    style: AppTextStyle.gropled(
                      fontSize: 14,
                      height: 1.35,
                      color: selected
                          ? AppTheme.primaryColor.withOpacity(0.85)
                          : AppTheme.backgroundColor.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Заказчик: задача ─────────────────────────────────────────────────────
  Widget _stepCustomerWork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Что вам нужно\nсделать?',
          'Выберите категорию',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _serviceLines.map((m) {
            final id = m['id']!;
            final label = '${m['emoji']}  ${m['label']}';
            final sel = _workCategoryId == id;
            return GestureDetector(
              onTap: () => setState(() => _workCategoryId = id),
              child: _chip(label, sel),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Заказчик: пространство ───────────────────────────────────────────────
  Widget _stepCustomerSpace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepTitle(
          'Опишите ваше\nпространство',
          'Тип помещения и примерная площадь',
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
          alignment: WrapAlignment.center,
          children: _premises.map((p) {
            final id = p['id']!;
            final label = p['label']!;
            final sel = _premiseKind == id;
            return GestureDetector(
              onTap: () => setState(() {
                _premiseKind = id;
                // Сбрасываем этажи при смене типа помещения
                if (id != 'house') _houseFloors = null;
              }),
              child: _compactChip(label, sel),
            );
          }).toList(),
        ),
        // Вопрос про этажи только для дома
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
            alignment: WrapAlignment.center,
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
          'Площадь примерно',
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
          alignment: WrapAlignment.center,
          children: _areas.map((a) {
            final id = a['id']!;
            final label = a['label']!;
            final sel = _areaId == id;
            return GestureDetector(
              onTap: () => setState(() => _areaId = id),
              child: _compactChip(label, sel),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        if (_premiseKind != null)
          _buildSuggestedRooms(_premiseKind!),
      ],
    );
  }

  Widget _buildSuggestedRooms(String premiseKind) {
    final rooms = _suggestedRoomsForPremise(premiseKind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Часто встречающиеся помещения (предложенные):',
          style: AppTextStyle.gropled(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.backgroundColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: rooms.map((r) => _compactChip(r, false)).toList(),
        ),
      ],
    );
  }

  List<String> _suggestedRoomsForPremise(String? kind) {
    switch (kind) {
      case 'apartment':
        return [
          'Жилая зона / гостиная',
          'Кухня',
          'Спальня',
          'Санузел',
          'Прихожая',
          'Балкон/лоджия',
        ];
      case 'house':
        return [
          'Гостиная',
          'Кухня',
          'Спальни',
          'Санузел(ы)',
          'Кладовая',
          'Терраса',
        ];
      case 'office':
        return [
          'Офисное пространство',
          'Перегородки',
          'Залы/зоны',
          'Санузел',
        ];
      default:
        return ['Прихожая', 'Кухня', 'Спальня', 'Санузел'];
    }
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
      margin: const EdgeInsets.all(2),
      padding: EdgeInsets.symmetric(
        horizontal: sel ? 18 : 16,
        vertical: sel ? 12 : 11,
      ),
      decoration: BoxDecoration(
        color: sel ? AppTheme.backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.backgroundColor.withOpacity(sel ? 1 : 0.35),
          width: sel ? 2 : 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 20, inherit: false)),
            const SizedBox(width: 8),
          ],
          Flexible(
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
