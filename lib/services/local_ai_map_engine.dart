/// Локальная заглушка ИИ-карты (без бэкенда): патч только после approved.
class LocalAiMapEngine {
  AiMapApplyResult apply({
    required String message,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    String apartmentId = 'arthouse_project',
    String apartmentName = 'Мой объект',
    bool approved = false,
  }) {
    final base = _bootstrapMap(
      currentMap,
      premiseRooms,
      apartmentId,
      apartmentName,
    );

    if (!approved) {
      return AiMapApplyResult(
        replyText: _replyWhenNotApproved(message, base),
        unityMap: base,
        focusRoomId: _guessFocusRoom(base, message),
        source: 'pending_approval',
        patchApplied: false,
      );
    }

    final before = _deepCopyMap(base);
    final merged = _applyStub(message, base);
    final patch = _extractPatch(before, merged);

    return AiMapApplyResult(
      replyText: _replyAfterApply(message, merged, patch),
      unityMap: merged,
      unityMapPatch: patch,
      focusRoomId: _guessFocusRoom(merged, message),
      source: 'stub',
      patchApplied: true,
    );
  }

  Map<String, dynamic> _bootstrapMap(
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    String apartmentId,
    String apartmentName,
  ) {
    if (currentMap != null && (currentMap['rooms'] as List?)?.isNotEmpty == true) {
      return _deepCopyMap(currentMap);
    }
    if (premiseRooms != null && premiseRooms.isNotEmpty) {
      final rooms = premiseRooms.map((r) {
        final id = r['roomId']?.toString() ?? r['id']?.toString() ?? 'room';
        final name = r['displayName']?.toString() ?? r['title']?.toString() ?? id;
        return {
          'roomId': id,
          'displayName': name,
          'gridSize': {'x': 6, 'y': 5},
          'floorMaterialId': 'floor_laminate_light',
          'wallMaterialId': 'wall_warm_white',
          'walls': <dynamic>[],
          'openings': <dynamic>[],
          'stairs': <dynamic>[],
          'furniture': <dynamic>[],
        };
      }).toList();
      return {
        'apartmentId': apartmentId,
        'apartmentName': apartmentName,
        'rooms': rooms,
        'tasks': <dynamic>[],
      };
    }
    return {
      'apartmentId': apartmentId,
      'apartmentName': apartmentName,
      'rooms': <dynamic>[],
      'tasks': <dynamic>[],
    };
  }

  Map<String, dynamic> _applyStub(String message, Map<String, dynamic> base) {
    final text = message.toLowerCase();
    final merged = _deepCopyMap(base);
    final rooms = (merged['rooms'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    String? floorId;
    String? wallId;
    if (_hasAny(text, ['паркет', 'дуб', 'oak'])) {
      floorId = 'floor_oak';
    } else if (text.contains('плитк')) {
      floorId = 'floor_tile_white';
    } else if (text.contains('ламинат')) {
      floorId = 'floor_laminate_light';
    }

    if (_hasAny(text, ['бел', 'светл']) && text.contains('стен')) {
      wallId = 'wall_warm_white';
    } else if (text.contains('сер') && text.contains('стен')) {
      wallId = 'wall_grey';
    }

    final target = _findRoomByMessage(rooms, text);
    if (target != null) {
      if (floorId != null) target['floorMaterialId'] = floorId;
      if (wallId != null) target['wallMaterialId'] = wallId;
    } else if (floorId != null || wallId != null) {
      for (final room in rooms) {
        if (floorId != null) room['floorMaterialId'] = floorId;
        if (wallId != null) room['wallMaterialId'] = wallId;
      }
    }

    merged['rooms'] = rooms;
    return merged;
  }

  Map<String, dynamic> _extractPatch(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    final beforeRooms = {
      for (final r in (before['rooms'] as List?) ?? [])
        if (r is Map) r['roomId']?.toString(): Map<String, dynamic>.from(r as Map),
    };
    final afterRooms = (after['rooms'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final roomsUpsert = <Map<String, dynamic>>[];
    for (final room in afterRooms) {
      final id = room['roomId']?.toString();
      if (id == null) continue;
      final prev = beforeRooms[id];
      if (prev == null || !_mapsEqual(prev, room)) {
        roomsUpsert.add(Map<String, dynamic>.from(room));
      }
    }
    return {
      'patchVersion': 1,
      'roomsUpsert': roomsUpsert,
      'tasksUpsert': <dynamic>[],
      'taskIdsRemove': <dynamic>[],
    };
  }

  String _replyWhenNotApproved(String message, Map<String, dynamic> base) {
    final room = _findRoomByMessage(
      (base['rooms'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      message.toLowerCase(),
    );
    if (room != null) {
      return 'Зафиксировал пожелания по «${room['displayName']}». '
          'Нажмите «Согласовать → на карту», чтобы применить изменения.';
    }
    return 'Опишите комнату или поверхность. '
        'На 3D-карту отправим изменения только после согласования.';
  }

  String _replyAfterApply(
    String message,
    Map<String, dynamic> merged,
    Map<String, dynamic> patch,
  ) {
    final n = ((patch['roomsUpsert'] as List?)?.length ?? 0);
    if (n > 0) {
      return 'Применено на карту: обновлено комнат — $n.';
    }
    return 'Согласовано. Уточните материалы или комнату, если нужно изменить карту.';
  }

  Map<String, dynamic>? _findRoomByMessage(
    List<Map<String, dynamic>> rooms,
    String text,
  ) {
    for (final room in rooms) {
      final name = (room['displayName'] ?? '').toString().toLowerCase();
      final id = (room['roomId'] ?? '').toString().toLowerCase();
      if (name.isNotEmpty && text.contains(name)) return room;
      if (id.isNotEmpty && text.contains(id.replaceAll('room_', '').replaceAll('_', ' '))) {
        return room;
      }
    }
    const keys = {
      'кухн': 'кухн',
      'гостин': 'гостин',
      'спальн': 'спальн',
      'ванн': 'ванн',
      'сануз': 'сануз',
      'прихож': 'прихож',
      'детск': 'детск',
    };
    for (final entry in keys.entries) {
      if (!text.contains(entry.key)) continue;
      for (final room in rooms) {
        final name = (room['displayName'] ?? '').toString().toLowerCase();
        if (name.contains(entry.value)) return room;
      }
    }
    return null;
  }

  String? _guessFocusRoom(Map<String, dynamic> map, String message) {
    final room = _findRoomByMessage(
      (map['rooms'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      message.toLowerCase(),
    );
    return room?['roomId']?.toString();
  }

  bool _hasAny(String text, List<String> words) =>
      words.any((w) => text.contains(w));

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) =>
      a.toString() == b.toString();

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> src) =>
      Map<String, dynamic>.from(
        Map<String, dynamic>.from(src).map(
          (k, v) => MapEntry(k, _deepCopyValue(v)),
        ),
      );

  dynamic _deepCopyValue(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.from(
        v.map((k, val) => MapEntry(k.toString(), _deepCopyValue(val))),
      );
    }
    if (v is List) return v.map(_deepCopyValue).toList();
    return v;
  }
}

class AiMapApplyResult {
  const AiMapApplyResult({
    required this.replyText,
    required this.unityMap,
    this.unityMapPatch,
    this.focusRoomId,
    required this.source,
    required this.patchApplied,
  });

  final String replyText;
  final Map<String, dynamic> unityMap;
  final Map<String, dynamic>? unityMapPatch;
  final String? focusRoomId;
  final String source;
  final bool patchApplied;
}
