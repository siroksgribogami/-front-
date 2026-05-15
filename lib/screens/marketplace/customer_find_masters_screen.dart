import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
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

  String _selectedMasterId = '';
  String _query = '';

  void _openMaster(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MasterPublicProfileScreen(masterId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    final filtered = _query.isEmpty
        ? _masters
        : _masters
            .where((m) =>
                m.name.toLowerCase().contains(_query.toLowerCase()) ||
                m.specialty.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 20),
              children: [
                Text(
                  'Поиск мастеров',
                  style: TextStyle(
                    fontFamily: AppTextStyle.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: AppTextStyle.defaultHeight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Нажмите на карточку, чтобы открыть профиль и связаться.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: AppTextStyle.defaultHeight,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Город, район, тип работ…',
                    filled: true,
                    fillColor: card,
                    hintStyle: TextStyle(color: textSecondary.withOpacity(0.9)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'По запросу никого не нашли',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MasterTile(
                        master: m,
                        isSelected: _selectedMasterId == m.id,
                        onTap: () {
                          setState(() => _selectedMasterId = m.id);
                          _openMaster(context, m.id);
                        },
                      ),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _MasterTile({
    required this.master,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? MarketplaceColors.bluePrimary.withOpacity(0.12)
          : MarketplaceColors.cardFor(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: MarketplaceColors.bluePrimary.withOpacity(0.22),
                child: Text(
                  master.name.isNotEmpty ? master.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MarketplaceColors.textPrimaryFor(context),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      master.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MarketplaceColors.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      master.specialty,
                      style: TextStyle(
                        fontSize: 13,
                        color: MarketplaceColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: MarketplaceColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        master.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MarketplaceColors.textPrimaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${master.jobs} заказов',
                    style: TextStyle(
                      fontSize: 12,
                      color: MarketplaceColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
