import 'dart:convert';

import 'package:flutter/services.dart';

/// Смета на клиенте: ИИ только catalog_work_id + qty; цены из assets.
class LocalEstimateEngine {
  static List<Map<String, dynamic>>? _catalogItems;

  Future<List<Map<String, dynamic>>> getCatalogForLlm() async {
    final items = await _loadItems();
    return items
        .map(
          (e) => {
            'id': e['id'],
            'title': e['title'],
            'unit': e['unit'],
            'section_title': e['section_title'],
          },
        )
        .toList();
  }

  Future<EstimateCompileResult> compile({
    List<Map<String, dynamic>>? selections,
    String? message,
    double reservePercent = 12,
  }) async {
    final used = selections ??
        (message != null && message.isNotEmpty
            ? await stubSelectionsFromText(message)
            : <Map<String, dynamic>>[]);

    final estimate = await _compileSelections(used, reservePercent);
    return EstimateCompileResult(
      estimate: estimate,
      selectionsUsed: used,
      hasMissingPrices: estimate['has_missing_prices'] == true,
    );
  }

  Future<List<Map<String, dynamic>>> stubSelectionsFromText(String message) async {
    final text = message.toLowerCase();
    final items = await _loadItems();

    final picks = <Map<String, dynamic>>[];
    for (final item in items) {
      final keywords = (item['keywords'] as List?)?.cast<String>() ?? [];
      if (keywords.isEmpty) continue;
      final hit = keywords.any((k) => text.contains(k.toLowerCase()));
      if (!hit) continue;
      picks.add({
        'catalog_work_id': item['id'],
        'qty': _defaultQty(item['unit']?.toString() ?? 'm2'),
      });
    }
    return picks;
  }

  Future<Map<String, dynamic>> _compileSelections(
    List<Map<String, dynamic>> selections,
    double reservePercent,
  ) async {
    final items = await _loadItems();
    final byId = {for (final i in items) i['id']?.toString(): i};

    final lines = <Map<String, dynamic>>[];
    for (final sel in selections) {
      final id = sel['catalog_work_id']?.toString();
      final qty = (sel['qty'] as num?)?.toDouble() ?? 0;
      final item = id != null ? byId[id] : null;

      if (item == null) {
        lines.add({
          'catalog_work_id': id,
          'title': 'Неизвестная позиция',
          'qty': qty,
          'unit': 'm2',
          'price_per_unit': null,
          'line_total': null,
          'price_missing': true,
        });
        continue;
      }

      final price = (item['price_per_unit'] as num?)?.toDouble() ?? 0;
      lines.add({
        'catalog_work_id': id,
        'title': item['title'],
        'qty': qty,
        'unit': item['unit'],
        'price_per_unit': price,
        'line_total': price * qty,
        'price_missing': false,
        'section_code': item['section_code'],
        'section_title': item['section_title'],
      });
    }

    final subtotal = lines
        .where((l) => l['price_missing'] != true)
        .fold<double>(0, (s, l) => s + ((l['line_total'] as num?)?.toDouble() ?? 0));

    final reserve = subtotal * reservePercent / 100;
    final grand = subtotal + reserve;

    final sections = _groupBySection(lines);

    return {
      'currency': 'RUB',
      'sections': sections,
      'totals': {
        'subtotal': subtotal,
        'reserve_percent': reservePercent,
        'reserve_amount': reserve,
        'grand_total': grand,
      },
      'has_missing_prices': lines.any((l) => l['price_missing'] == true),
    };
  }

  List<Map<String, dynamic>> _groupBySection(List<Map<String, dynamic>> lines) {
    final map = <String, Map<String, dynamic>>{};
    for (final line in lines) {
      final code = line['section_code']?.toString() ?? '99';
      final title = line['section_title']?.toString() ?? 'Прочее';
      map.putIfAbsent(
        code,
        () => {'section_code': code, 'section_title': title, 'lines': <Map<String, dynamic>>[]},
      );
      (map[code]!['lines'] as List).add(line);
    }
    return map.values.toList();
  }

  double _defaultQty(String unit) {
    switch (unit) {
      case 'pcs':
        return 4;
      case 'lm':
        return 12;
      default:
        return 18;
    }
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    if (_catalogItems != null) return _catalogItems!;
    final raw = await rootBundle.loadString('assets/data/work_price_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _catalogItems =
        (json['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ??
            [];
    return _catalogItems!;
  }
}

class EstimateCompileResult {
  const EstimateCompileResult({
    required this.estimate,
    required this.selectionsUsed,
    required this.hasMissingPrices,
  });

  final Map<String, dynamic> estimate;
  final List<Map<String, dynamic>> selectionsUsed;
  final bool hasMissingPrices;
}
