import 'api_service.dart';

/// Ответ ИИ-прораба (OpenRouter / stub на бэкенде).
class AiForemanChatResult {
  final String text;
  final String emotion;
  final String stage;
  final Map<String, dynamic> objectCard;
  final Map<String, dynamic>? unityMap;
  final Map<String, dynamic>? unityMapPatch;
  final bool estimateReady;
  final bool patchApplied;
  final int? threadId;
  final Map<String, dynamic>? projectMapData;
  final String source;

  const AiForemanChatResult({
    required this.text,
    this.emotion = 'обычный',
    this.stage = 'discovery',
    this.objectCard = const {},
    this.unityMap,
    this.unityMapPatch,
    this.estimateReady = false,
    this.patchApplied = false,
    this.threadId,
    this.projectMapData,
    this.source = 'stub',
  });

  factory AiForemanChatResult.fromJson(Map<String, dynamic> raw) {
    return AiForemanChatResult(
      text: (raw['text'] ?? raw['reply_text'] ?? '').toString(),
      emotion: (raw['emotion'] ?? 'обычный').toString(),
      stage: (raw['stage'] ?? 'discovery').toString(),
      objectCard: _map(raw['object_card']),
      unityMap: raw['unity_map'] is Map
          ? _map(raw['unity_map'] as Map)
          : null,
      unityMapPatch: raw['unity_map_patch'] is Map
          ? _map(raw['unity_map_patch'] as Map)
          : null,
      estimateReady: raw['estimate_ready'] == true,
      patchApplied: raw['patch_applied'] == true,
      threadId: raw['thread_id'] is int ? raw['thread_id'] as int : null,
      projectMapData: raw['project_map_data'] is Map
          ? _map(raw['project_map_data'] as Map)
          : null,
      source: (raw['source'] ?? 'stub').toString(),
    );
  }

  static Map<String, dynamic> _map(Map raw) =>
      raw.map((k, v) => MapEntry(k.toString(), v));
}

/// ИИ-1 Прораб: `/ai-foreman/chat` → object_card + unity_map_patch.
class AiForemanService {
  final ApiService _api;

  AiForemanService({ApiService? api}) : _api = api ?? ApiService();

  Future<AiForemanChatResult> chat({
    required String message,
    int? threadId,
    int? projectId,
    Map<String, dynamic>? objectCard,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    Map<String, dynamic>? survey,
    bool approved = false,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      if (threadId != null) 'thread_id': threadId,
      if (projectId != null) 'project_id': projectId,
      if (objectCard != null && objectCard.isNotEmpty) 'object_card': objectCard,
      if (currentMap != null && currentMap.isNotEmpty) 'current_map': currentMap,
      if (premiseRooms != null && premiseRooms.isNotEmpty)
        'premise_rooms': premiseRooms,
      if (survey != null) 'survey': survey,
      'approved': approved,
    };

    final resp = await _api.post('/ai-foreman/chat', body: body);
    if (resp is Map<String, dynamic>) {
      return AiForemanChatResult.fromJson(resp);
    }
    return AiForemanChatResult(text: resp?.toString() ?? '');
  }
}
