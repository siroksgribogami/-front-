import 'dart:convert';

/// Merge diff-патча в JSON карты (как [unity_bridge_host.html]).
Map<String, dynamic> mergeUnityMapPatch(
  Map<String, dynamic> base,
  Map<String, dynamic> patch,
) {
  final merged = Map<String, dynamic>.from(base);
  final roomsById = <String, Map<String, dynamic>>{};
  for (final room in (merged['rooms'] as List?) ?? const []) {
    if (room is Map) {
      final id = room['roomId']?.toString();
      if (id != null && id.isNotEmpty) {
        roomsById[id] = Map<String, dynamic>.from(room);
      }
    }
  }

  for (final room in (patch['roomsUpsert'] as List?) ?? const []) {
    if (room is! Map) continue;
    final id = room['roomId']?.toString();
    if (id == null || id.isEmpty) continue;
    final existing = roomsById[id] ?? {'roomId': id};
    roomsById[id] = {...existing, ...Map<String, dynamic>.from(room)};
  }
  merged['rooms'] = roomsById.values.toList();

  final tasksById = <String, Map<String, dynamic>>{};
  for (final task in (merged['tasks'] as List?) ?? const []) {
    if (task is Map) {
      final id = task['taskId']?.toString();
      if (id != null && id.isNotEmpty) {
        tasksById[id] = Map<String, dynamic>.from(task);
      }
    }
  }
  for (final id in (patch['taskIdsRemove'] as List?) ?? const []) {
    tasksById.remove(id.toString());
  }
  for (final task in (patch['tasksUpsert'] as List?) ?? const []) {
    if (task is Map) {
      final id = task['taskId']?.toString();
      if (id != null && id.isNotEmpty) {
        tasksById[id] = Map<String, dynamic>.from(task);
      }
    }
  }
  merged['tasks'] = tasksById.values.toList();
  return merged;
}

/// JavaScript для WebView: шлёт карту в Unity `ARTHouseMapBridge`.
String buildHostedUnityInjectScript({
  required String mapJson,
  Map<String, dynamic>? patch,
  String? focusRoomId,
  String bridgeObject = 'ARTHouseMapBridge',
  int maxAttempts = 80,
  int intervalMs = 400,
}) {
  var payload = mapJson;
  if (patch != null && patch.isNotEmpty) {
    try {
      final base = jsonDecode(mapJson.isEmpty ? '{}' : mapJson) as Map<String, dynamic>;
      payload = jsonEncode(mergeUnityMapPatch(base, patch));
    } catch (_) {
      payload = mapJson;
    }
  }

  final payloadLiteral = jsonEncode(payload);
  final focusLiteral = jsonEncode(focusRoomId ?? '');
  final bridgeLiteral = jsonEncode(bridgeObject);

  return '''
(function () {
  var mapJson = $payloadLiteral;
  var focusRoomId = $focusLiteral;
  var bridgeName = $bridgeLiteral;
  var attempts = 0;
  var maxAttempts = $maxAttempts;
  var intervalMs = $intervalMs;

  function sendMessage(method, arg) {
    var inst = window.unityInstance || window.gameInstance;
    if (inst && typeof inst.SendMessage === 'function') {
      inst.SendMessage(bridgeName, method, arg || '');
      return true;
    }
    if (typeof unitySendMessage === 'function') {
      unitySendMessage(bridgeName, method, arg || '');
      return true;
    }
    return false;
  }

  function pushMap() {
    if (!sendMessage('ReceiveInitialMapJson', mapJson)) return false;
    if (focusRoomId) sendMessage('FocusRoom', focusRoomId);
    return true;
  }

  var timer = setInterval(function () {
    attempts += 1;
    if (pushMap() || attempts >= maxAttempts) clearInterval(timer);
  }, intervalMs);
})();''';
}
