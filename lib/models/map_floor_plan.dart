/// Многоэтажная планировка в `mapData` (квартира, дом, офис).
///
/// Формат в JSON:
/// ```json
/// {
///   "floors": [
///     { "floor_index": 0, "label": "1 этаж", "area_sqm": 45, "rooms": [...] }
///   ],
///   "floors_count": 2,
///   "rooms": [...],  // плоский список для Unity / ИИ (с полями floor_index)
///   "total_area_sqm": 85
/// }
/// ```
class MapFloorData {
  MapFloorData({
    required this.index,
    required this.label,
    required this.rooms,
    this.areaSqm,
  });

  final int index;
  final String label;
  final List<Map<String, dynamic>> rooms;
  final int? areaSqm;

  MapFloorData copyWith({
    int? index,
    String? label,
    List<Map<String, dynamic>>? rooms,
    int? areaSqm,
  }) {
    return MapFloorData(
      index: index ?? this.index,
      label: label ?? this.label,
      rooms: rooms ?? this.rooms,
      areaSqm: areaSqm ?? this.areaSqm,
    );
  }

  Map<String, dynamic> toJson() => {
        'floor_index': index,
        'label': label,
        if (areaSqm != null) 'area_sqm': areaSqm,
        'rooms': rooms,
      };

  factory MapFloorData.fromJson(Map<String, dynamic> json) {
    final rawRooms = json['rooms'];
    final rooms = <Map<String, dynamic>>[];
    if (rawRooms is List) {
      for (final item in rawRooms) {
        if (item is Map) {
          rooms.add(item.cast<String, dynamic>());
        }
      }
    }
    return MapFloorData(
      index: (json['floor_index'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? '1 этаж',
      rooms: rooms,
      areaSqm: (json['area_sqm'] as num?)?.toInt(),
    );
  }
}

abstract final class MapFloorPlanHelper {
  MapFloorPlanHelper._();

  static String labelForIndex(int index) => '${index + 1} этаж';

  /// Читает этажи из блока `before` / `after` или legacy `rooms`.
  static List<MapFloorData> floorsFromBlock(Map<String, dynamic>? block) {
    if (block == null) return [];

    final rawFloors = block['floors'];
    if (rawFloors is List && rawFloors.isNotEmpty) {
      final parsed = <MapFloorData>[];
      for (final item in rawFloors) {
        if (item is Map) {
          parsed.add(MapFloorData.fromJson(item.cast<String, dynamic>()));
        }
      }
      parsed.sort((a, b) => a.index.compareTo(b.index));
      return parsed;
    }

    final legacyRooms = block['rooms'];
    if (legacyRooms is List && legacyRooms.isNotEmpty) {
      final byFloor = <int, List<Map<String, dynamic>>>{};
      for (final item in legacyRooms) {
        if (item is! Map) continue;
        final room = item.cast<String, dynamic>();
        final fi = (room['floor_index'] as num?)?.toInt() ?? 0;
        byFloor.putIfAbsent(fi, () => []).add(room);
      }
      if (byFloor.length > 1 || byFloor.keys.any((k) => k > 0)) {
        return byFloor.entries
            .map(
              (e) => MapFloorData(
                index: e.key,
                label: labelForIndex(e.key),
                rooms: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
      }
      return [
        MapFloorData(
          index: 0,
          label: labelForIndex(0),
          rooms: legacyRooms
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(),
          areaSqm: (block['total_area_sqm'] as num?)?.toInt(),
        ),
      ];
    }

    return [];
  }

  /// Плоский список комнат с метками этажа (для Unity / списков).
  static List<Map<String, dynamic>> flattenRooms(List<MapFloorData> floors) {
    final out = <Map<String, dynamic>>[];
    for (final floor in floors) {
      for (final room in floor.rooms) {
        out.add({
          ...room,
          'floor_index': floor.index,
          'floor_label': floor.label,
        });
      }
    }
    return out;
  }

  static int totalAreaSqm(List<MapFloorData> floors) {
    var sum = 0;
    for (final f in floors) {
      if (f.areaSqm != null && f.areaSqm! > 0) {
        sum += f.areaSqm!;
        continue;
      }
      for (final r in f.rooms) {
        sum += (r['area_sqm'] as num?)?.toInt() ?? 0;
      }
    }
    return sum;
  }

  /// Собирает payload для `mapData.after` / `before`.
  static Map<String, dynamic> blockPayload({
    required List<MapFloorData> floors,
    String source = 'sketch_wizard',
  }) {
    final total = totalAreaSqm(floors);
    return {
      'floors': floors.map((f) => f.toJson()).toList(),
      'floors_count': floors.length,
      'rooms': flattenRooms(floors),
      'total_area_sqm': total > 0 ? total : null,
      'source': source,
    };
  }

  /// Черновик `after` после опроса: один этаж — legacy, несколько — `floors[]`.
  static Map<String, dynamic> initialAfterFromCatalog({
    required List<Map<String, dynamic>> catalogRooms,
    required int floorsCount,
    String source = 'post_register_survey',
  }) {
    final count = floorsCount.clamp(1, 10);
    if (count <= 1) {
      return {
        'rooms': catalogRooms,
        'floors_count': 1,
        'source': source,
      };
    }
    final floors = List.generate(
      count,
      (i) => MapFloorData(
        index: i,
        label: labelForIndex(i),
        rooms: i == 0 ? catalogRooms : <Map<String, dynamic>>[],
      ),
    );
    return blockPayload(floors: floors, source: source);
  }

  /// Сколько этажей предложить по типу объекта (опрос / профиль).
  static int suggestedFloorCount({
    String? premiseType,
    String? houseFloors,
    int? floorsCount,
  }) {
    if (floorsCount != null && floorsCount > 0) {
      return floorsCount.clamp(1, 10);
    }
    if (houseFloors != null && houseFloors.isNotEmpty) {
      final n = int.tryParse(houseFloors);
      if (n != null && n > 0) return n.clamp(1, 10);
    }
    switch (premiseType) {
      case 'house':
        return 2;
      case 'office':
      case 'commerce':
        return 2;
      case 'hotel':
        return 3;
      default:
        return 1;
    }
  }
}
