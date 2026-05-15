import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Сохранение истории сообщений на устройстве до подключения сервера чата.
class ChatLocalStore {
  ChatLocalStore._();
  static final ChatLocalStore instance = ChatLocalStore._();

  static const _key = 'arthouse_chat_messages_v1';

  Future<Map<String, List<Map<String, dynamic>>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, List<Map<String, dynamic>>>{};
      decoded.forEach((k, v) {
        final list = (v as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        out[k] = list;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAll(Map<String, List<Map<String, dynamic>>> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    chats.forEach((k, v) {
      encoded[k] = v;
    });
    await prefs.setString(_key, jsonEncode(encoded));
  }
}
