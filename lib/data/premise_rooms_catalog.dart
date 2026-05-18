import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Каталог типовых помещений по типу объекта (опрос → ИИ-прораб → Unity-карта).
class PremiseRoomsCatalog {
  PremiseRoomsCatalog._();

  static const prefsKey = 'arthouse_premise_rooms_json';

  static List<String> suggestedRoomLabels(String premiseKind) {
    switch (premiseKind) {
      case 'apartment':
        return const [
          'Жилая зона / гостиная',
          'Кухня',
          'Спальня',
          'Санузел',
          'Прихожая',
          'Балкон/лоджия',
        ];
      case 'house':
        return const [
          'Гостиная',
          'Кухня',
          'Спальни',
          'Санузел(ы)',
          'Кладовая',
          'Терраса',
        ];
      case 'office':
        return const [
          'Офисное пространство',
          'Перегородки',
          'Залы/зоны',
          'Санузел',
        ];
      default:
        return const ['Прихожая', 'Кухня', 'Спальня', 'Санузел'];
    }
  }

  /// Структура комнат для `map_data.rooms` и контекста ИИ (нейросеть может уточнить позже).
  static List<Map<String, dynamic>> roomsForMap(
    String premiseKind, {
    String source = 'onboarding_catalog',
  }) {
    final labels = suggestedRoomLabels(premiseKind);
    return List.generate(labels.length, (index) {
      final name = labels[index];
      final roomId = _roomIdFromName(name, index);
      return <String, dynamic>{
        'id': roomId,
        'roomId': roomId,
        'name': name,
        'displayName': name,
        'source': source,
        'confirmed': false,
      };
    });
  }

  static String _roomIdFromName(String name, int index) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zа-яё0-9]+', caseSensitive: false), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isNotEmpty) return 'room_$slug';
    return 'room_$index';
  }

  static Future<void> persistRoomsJson(List<Map<String, dynamic>> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(rooms));
  }

  static Future<List<Map<String, dynamic>>?> loadPersistedRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
