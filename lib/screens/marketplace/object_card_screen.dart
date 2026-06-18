import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_runtime.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';

/// Экран «Карточка объекта» — единый артефакт ИИ-прораба (object_card):
/// паспорт, комнаты с размерами, что меняем, смета. Когда смета готова —
/// карточку можно опубликовать на бирже мастеров.
class ObjectCardScreen extends StatefulWidget {
  const ObjectCardScreen({
    super.key,
    required this.objectCard,
    this.projectId,
  });

  final Map<String, dynamic> objectCard;
  final int? projectId;

  static Future<void> open(
    BuildContext context, {
    required Map<String, dynamic> objectCard,
    int? projectId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ObjectCardScreen(
          objectCard: objectCard,
          projectId: projectId,
        ),
      ),
    );
  }

  @override
  State<ObjectCardScreen> createState() => _ObjectCardScreenState();
}

class _ObjectCardScreenState extends State<ObjectCardScreen> {
  bool _publishing = false;

  Map<String, dynamic> get _card => widget.objectCard;

  Map<String, dynamic> _section(String key) {
    final v = _card[key];
    return v is Map ? v.map((k, val) => MapEntry(k.toString(), val)) : {};
  }

  Map<String, dynamic> get _passport => _section('passport');
  Map<String, dynamic> get _design => _section('design');
  Map<String, dynamic> get _after => _section('after');
  Map<String, dynamic> get _estimate => _section('estimate');

  List<Map<String, dynamic>> get _rooms {
    final r = _card['rooms'];
    if (r is! List) return const [];
    return r
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  num? get _grandTotal {
    final totals = _estimate['totals'];
    if (totals is Map && totals['grand_total'] is num) {
      return totals['grand_total'] as num;
    }
    return null;
  }

  bool get _estimateReady {
    final sections = _estimate['sections'];
    return sections is List && sections.isNotEmpty;
  }

  String get _title {
    final meta = _section('meta');
    final metaTitle = (meta['title'] ?? '').toString().trim();
    if (metaTitle.isNotEmpty) return metaTitle;
    final goal = (_passport['goal'] ?? '').toString().trim();
    final type = (_passport['object_type'] ?? '').toString().trim();
    if (goal.isNotEmpty && type.isNotEmpty) return '$goal · $type';
    if (goal.isNotEmpty) return goal;
    return 'Проект ремонта';
  }

  String _num(Object? v, {String suffix = ''}) {
    if (v == null) return '—';
    if (v is num) {
      final s = v % 1 == 0 ? v.toInt().toString() : v.toString();
      return '$s$suffix';
    }
    return v.toString();
  }

  String _money(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf ₽';
  }

  // ---- сборка ТЗ для мастера из object_card ----
  String _buildSpec() {
    final lines = <String>[];
    void add(String label, Object? v) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty && s != 'null') lines.add('$label: $s');
    }

    add('Цель', _passport['goal']);
    add('Тип объекта', _passport['object_type']);
    add('Город', _passport['city']);
    add('Площадь, м²', _passport['total_area_sqm'] ?? _passport['total_area_m2']);
    add('Потолки, м', _passport['ceiling_height_m']);
    add('Комнат', _passport['rooms_count']);
    add('Стиль', _design['style']);

    if (_rooms.isNotEmpty) {
      final r = _rooms.map((room) {
        final name = (room['name'] ?? '').toString();
        final w = room['width_m'];
        final l = room['length_m'];
        final a = room['area_sqm'] ?? room['area_m2'];
        final dim = (w != null && l != null) ? ' ${_num(w)}×${_num(l)} м' : '';
        final area = a != null ? ' (${_num(a)} м²)' : '';
        return '$name$dim$area';
      }).join('; ');
      lines.add('Комнаты: $r');
    }

    final afterSummary = (_after['summary'] ?? '').toString().trim();
    if (afterSummary.isNotEmpty) lines.add('Желаемый результат: $afterSummary');

    if (_grandTotal != null) {
      lines.add('Ориентировочная смета: ${_money(_grandTotal!)}');
    }
    return lines.join('\n');
  }

  String get _workTypeForFeed {
    final sections = _estimate['sections'];
    if (sections is List && sections.isNotEmpty) {
      final first = sections.first;
      if (first is Map && (first['title'] ?? '').toString().isNotEmpty) {
        return first['title'].toString();
      }
    }
    final goal = (_passport['goal'] ?? '').toString().trim();
    return goal.isNotEmpty ? goal : 'Ремонт';
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      final store = MarketplaceLocalStore.instance;
      await store.ensureLoaded();

      final city = (_passport['city'] ?? '').toString().trim();
      final budget = _grandTotal != null ? _money(_grandTotal!) : '';
      final project = ProjectSummary(
        id: widget.projectId?.toString() ??
            'p_${DateTime.now().millisecondsSinceEpoch}',
        title: _title,
        status: 'Опубликован',
        updatedAt: DateTime.now(),
        mapData: {
          'object_card': _card,
        },
        workType: _workTypeForFeed,
        budget: budget,
        address: city,
        spec: _buildSpec(),
      );

      final list = [...store.customerProjects];
      final idx = list.indexWhere((p) => p.id == project.id);
      if (idx == -1) {
        list.insert(0, project);
      } else {
        list[idx] = project;
      }
      await store.saveCustomerProjects(list);
      await store.syncPublishedProject(
        project,
        districtLine: city.isEmpty ? 'Регион уточняется у заказчика' : city,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Карточка опубликована на бирже')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: Column(
          children: [
            BrandAppBar(
              title: 'Карточка объекта',
              subtitle: 'Что увидят мастера на бирже',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _heroCard(),
                  const SizedBox(height: 16),
                  _passportSection(),
                  if (_rooms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _roomsSection(),
                  ],
                  if ((_after['summary'] ?? '').toString().trim().isNotEmpty ||
                      (_design['style'] ?? '').toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _afterSection(),
                  ],
                  const SizedBox(height: 16),
                  _estimateSection(),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrandRuntime.needles,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: pochaevsk(fontSize: 22, color: BrandRuntime.card, height: 1.05),
          ),
          const SizedBox(height: 6),
          Text(
            _estimateReady
                ? 'Готово к публикации на бирже мастеров'
                : 'Черновик — диалог с прорабом ещё идёт',
            style: BrandUi.inter(
              fontSize: 13,
              color: BrandColors.dawn.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card_(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandRuntime.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandKicker(title),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: BrandUi.inter(
                fontSize: 13,
                color: BrandRuntime.ink.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: BrandUi.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BrandRuntime.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passportSection() {
    final rows = <Widget>[];
    void row(String k, Object? v, {String suffix = ''}) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty || s == 'null') return;
      rows.add(_kv(k, '$s$suffix'));
    }

    row('Цель', _passport['goal']);
    row('Тип объекта', _passport['object_type']);
    row('Город / район', _passport['city']);
    row('Площадь', _passport['total_area_sqm'] ?? _passport['total_area_m2'],
        suffix: ' м²');
    row('Потолки', _passport['ceiling_height_m'], suffix: ' м');
    row('Комнат', _passport['rooms_count']);
    row('Бюджет', _passport['budget_rub'], suffix: ' ₽');
    row('Сроки', _passport['duration_weeks'], suffix: ' нед.');
    row('Тип мастера', _passport['master_type']);

    if (rows.isEmpty) {
      rows.add(Text(
        'Параметры объекта ещё собираются.',
        style: BrandUi.inter(fontSize: 13, color: BrandRuntime.ink.withOpacity(0.5)),
      ));
    }
    return _card_('Паспорт объекта', rows);
  }

  Widget _roomsSection() {
    return _card_(
      'Комнаты и размеры',
      _rooms.map((room) {
        final name = (room['name'] ?? 'Комната').toString();
        final w = room['width_m'];
        final l = room['length_m'];
        final a = room['area_sqm'] ?? room['area_m2'];
        final parts = <String>[];
        if (w != null && l != null) parts.add('${_num(w)} × ${_num(l)} м');
        if (a != null) parts.add('${_num(a)} м²');
        final detail = parts.isEmpty ? 'размеры уточняются' : parts.join(' · ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.crop_square_rounded,
                  size: 18, color: BrandColors.needlesDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: BrandUi.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                detail,
                style: BrandUi.inter(
                  fontSize: 13,
                  color: BrandRuntime.ink.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _afterSection() {
    final children = <Widget>[];
    final style = (_design['style'] ?? '').toString().trim();
    if (style.isNotEmpty) children.add(_kv('Стиль', style));
    final summary = (_after['summary'] ?? '').toString().trim();
    if (summary.isNotEmpty) {
      children.add(Text(
        summary,
        style: BrandUi.inter(
            fontSize: 14, height: 1.4, color: BrandRuntime.ink),
      ));
    }
    return _card_('Желаемый результат', children);
  }

  Widget _estimateSection() {
    final sections = _estimate['sections'];
    final children = <Widget>[];

    if (_grandTotal != null) {
      children.add(Row(
        children: [
          Text(
            'Итого ориентировочно',
            style: BrandUi.inter(
                fontSize: 14, color: BrandRuntime.ink.withOpacity(0.6)),
          ),
          const Spacer(),
          Text(
            _money(_grandTotal!),
            style: pochaevsk(fontSize: 22, color: BrandColors.clay, height: 1),
          ),
        ],
      ));
      children.add(const SizedBox(height: 10));
    }

    if (sections is List && sections.isNotEmpty) {
      for (final s in sections) {
        if (s is! Map) continue;
        final title = (s['title'] ?? '').toString();
        final subtotal = s['subtotal'];
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: BrandUi.inter(fontSize: 13.5)),
              ),
              if (subtotal is num)
                Text(_money(subtotal),
                    style: BrandUi.inter(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ));
      }
    } else {
      children.add(Text(
        'Смета появится, когда соберём виды работ в диалоге с прорабом.',
        style: BrandUi.inter(fontSize: 13, color: BrandRuntime.ink.withOpacity(0.5)),
      ));
    }
    return _card_('Смета', children);
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: BrandRuntime.canvas,
        border: Border(top: BorderSide(color: BrandRuntime.border)),
      ),
      child: _estimateReady
          ? SizedBox(
              width: double.infinity,
              child: BrandPrimaryButton(
                label: _publishing ? 'Публикуем…' : 'Опубликовать на бирже',
                onPressed: _publishing ? null : _publish,
              ),
            )
          : Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: BrandRuntime.ink.withOpacity(0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Допройдите диалог с прорабом до сметы — тогда появится публикация.',
                    style: BrandUi.inter(
                      fontSize: 12.5,
                      color: BrandRuntime.ink.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
