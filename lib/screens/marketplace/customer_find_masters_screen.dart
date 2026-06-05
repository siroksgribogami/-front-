import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../data/marketplace_seed_catalog.dart';
import 'master_public_profile_screen.dart';

/// Экран «Поиск мастеров» для заказчика.
class CustomerFindMastersScreen extends StatefulWidget {
  const CustomerFindMastersScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final countLabel = '${_masters.length} исполнителя';

    return ColoredBox(
      color: BrandColors.canvas,
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
                  color: BrandColors.needles,
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
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'По запросу никого не нашли',
                        style: BrandUi.inter(
                          color: BrandColors.tar.withOpacity(0.55),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 11),
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        return _MasterTile(
                          master: m,
                          index: i,
                          isSelected: _selectedMasterId == m.id,
                          onProfile: () {
                            setState(() => _selectedMasterId = m.id);
                            _openMaster(context, m.id);
                          },
                        );
                      },
                    ),
            ),
          ],
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
  final VoidCallback onProfile;

  const _MasterTile({
    required this.master,
    required this.index,
    required this.isSelected,
    required this.onProfile,
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
        color: BrandColors.milk,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? BrandColors.needles.withOpacity(0.5)
              : BrandColors.borderSubtle,
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
                          color: BrandColors.tar,
                          height: 1,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: BrandColors.needles,
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
                        color: BrandColors.tar.withOpacity(0.45),
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
                  color: BrandColors.needles,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: BrandColors.needles,
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
