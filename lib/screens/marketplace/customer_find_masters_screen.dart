import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../data/marketplace_seed_catalog.dart';
import 'foreman_intro_screen.dart';
import 'master_public_profile_screen.dart';

/// Экран «Поиск мастеров» для заказчика.
class CustomerFindMastersScreen extends StatefulWidget {
  const CustomerFindMastersScreen({super.key, this.recommendedSpecialties});

  /// Виды работ из object_card (ИИ-прораб) — для подбора первых 3–5 мастеров.
  final List<String>? recommendedSpecialties;

  @override
  State<CustomerFindMastersScreen> createState() => _CustomerFindMastersScreenState();
}

class _CustomerFindMastersScreenState extends State<CustomerFindMastersScreen> {
  static final List<_MasterEntry> _masters = MarketplaceSeedCatalog.masterSearchEntries
      .map(
        (m) => _MasterEntry(
          id: m['id']! as String,
          name: m['name']! as String,
          specialty: m['specialty']! as String,
          rating: (m['rating'] as num).toDouble(),
          jobs: (m['jobs'] as num).toInt(),
        ),
      )
      .toList();

  static const _categories = ['Все', 'Сантехника', 'Электрика', 'Отделка'];

  String _selectedMasterId = '';
  String _query = '';
  String _selectedCategory = 'Все';

  void _openMaster(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MasterPublicProfileScreen(masterId: id),
      ),
    );
  }

  List<_MasterEntry> get _filtered {
    var list = _masters;
    if (_selectedCategory != 'Все') {
      final key = _selectedCategory.toLowerCase();
      list = list.where((m) => m.specialty.toLowerCase().contains(key)).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.specialty.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  bool get _isDefaultView => _query.isEmpty && _selectedCategory == 'Все';

  /// Первые 3–5 мастеров «под проект»: совпадение по видам работ из ИИ-карточки,
  /// иначе — топ по рейтингу.
  List<_MasterEntry> get _recommended {
    final specs = widget.recommendedSpecialties;
    var ranked = [..._masters]..sort((a, b) => b.rating.compareTo(a.rating));
    if (specs != null && specs.isNotEmpty) {
      final keys = specs.map((s) => s.toLowerCase()).toList();
      final matched = ranked
          .where((m) => keys.any((k) =>
              m.specialty.toLowerCase().contains(k) ||
              k.contains(m.specialty.toLowerCase())))
          .toList();
      if (matched.isNotEmpty) ranked = matched;
    }
    return ranked.take(5).toList();
  }

  void _openForeman() => ForemanIntroScreen.open(context);

  @override
  Widget build(BuildContext context) {
    final countLabel = '${_masters.length} исполнителя';

    return ColoredBox(
      color: BrandRuntime.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandAppBar(
              title: 'Мастера',
              subtitle: countLabel,
              big: true,
              actions: BrandIconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: BrandRuntime.needles,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrandSearchField(
                    hint: 'Плиточник, электрик, бригада…',
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _categories.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          BrandChip(
                            label: _categories[i],
                            selected: _selectedCategory == _categories[i],
                            onTap: () => setState(() => _selectedCategory = _categories[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _tile(_MasterEntry m, int index, {bool recommended = false}) {
    return _MasterTile(
      master: m,
      index: index,
      isSelected: _selectedMasterId == m.id,
      recommended: recommended,
      onProfile: () {
        setState(() => _selectedMasterId = m.id);
        _openMaster(context, m.id);
      },
    );
  }

  Widget _buildBody() {
    if (!_isDefaultView) {
      final filtered = _filtered;
      if (filtered.isEmpty) {
        return Center(
          child: Text(
            'По запросу никого не нашли',
            style: BrandUi.inter(color: BrandRuntime.ink.withOpacity(0.55)),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, i) => _tile(filtered[i], i),
      );
    }

    final recommended = _recommended;
    final recIds = recommended.map((m) => m.id).toSet();
    final others = _masters.where((m) => !recIds.contains(m.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        _AiSuggestSpecialistCard(onTap: _openForeman),
        const SizedBox(height: 18),
        _sectionHeader('Подобрано ИИ-прорабом', recommended.length),
        const SizedBox(height: 11),
        for (var i = 0; i < recommended.length; i++) ...[
          if (i > 0) const SizedBox(height: 11),
          _tile(recommended[i], i, recommended: true),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionHeader('Остальные мастера', others.length),
          const SizedBox(height: 11),
          for (var i = 0; i < others.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            _tile(others[i], i + recommended.length),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: pochaevsk(fontSize: 18, color: BrandRuntime.ink, height: 1),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: BrandRuntime.needlesFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: BrandUi.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BrandColors.needlesDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточка-предложение ИИ-прораба позвать независимого специалиста
/// для оценки работ (Диана: «ИИ предложит вызвать стороннего специалиста»).
class _AiSuggestSpecialistCard extends StatelessWidget {
  const _AiSuggestSpecialistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.needlesLight.withOpacity(0.16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandColors.needlesLight.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_moon_outlined,
                    size: 21, color: BrandColors.needlesDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Нужна независимая оценка работ?',
                      style: BrandUi.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: BrandRuntime.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ИИ-прораб подберёт стороннего специалиста, чтобы проверить '
                      'ход и качество работ.',
                      style: BrandUi.inter(
                        fontSize: 12.5,
                        height: 1.35,
                        color: BrandRuntime.ink.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Спросить ИИ-прораба',
                          style: BrandUi.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.needlesDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: BrandColors.needlesDark),
                      ],
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

class _MasterEntry {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int jobs;

  const _MasterEntry({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.jobs,
  });
}

class _MasterTile extends StatelessWidget {
  final _MasterEntry master;
  final int index;
  final bool isSelected;
  final bool recommended;
  final VoidCallback onProfile;

  const _MasterTile({
    required this.master,
    required this.index,
    required this.isSelected,
    required this.onProfile,
    this.recommended = false,
  });

  static const _areas = ['Хамовники', 'ЦАО', 'Басманный', 'Якиманка'];
  static const _prices = [
    'от 1 800 ₽/м²',
    'от 9 500 ₽/м²',
    'от 750 ₽/точка',
    'от 600 ₽/м²',
  ];

  BrandAvatarTone get _tone {
    const tones = BrandAvatarTone.values;
    return tones[index % tones.length];
  }

  @override
  Widget build(BuildContext context) {
    final area = _areas[index % _areas.length];
    final price = _prices[index % _prices.length];
    final verified = index.isEven;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? BrandRuntime.needles.withOpacity(0.5)
              : BrandRuntime.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandAvatar(
            name: master.name,
            size: 54,
            radius: 15,
            tone: _tone,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        master.name,
                        style: pochaevsk(
                          fontSize: 18,
                          color: BrandRuntime.ink,
                          height: 1,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: BrandRuntime.needles,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  master.specialty,
                  style: BrandUi.inter(
                    fontSize: 13,
                    color: BrandColors.surik,
                  ),
                ),
                if (recommended) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrandRuntime.needlesFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Рекомендуем ИИ',
                      style: BrandUi.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.needlesDark,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    BrandStars(value: master.rating, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      master.rating.toStringAsFixed(1),
                      style: BrandUi.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' · ${master.jobs} отзывов · $area',
                      style: BrandUi.inter(
                        fontSize: 12.5,
                        color: BrandRuntime.ink.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                textAlign: TextAlign.right,
                style: BrandUi.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: BrandRuntime.needles,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: BrandRuntime.needles,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      'Профиль',
                      style: BrandUi.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.onNeedles,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
