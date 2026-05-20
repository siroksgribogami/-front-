import 'ai_vision_service.dart';
import 'api_service.dart';
import 'local_ai_map_engine.dart';

export 'local_ai_map_engine.dart' show AiMapApplyResult;

/// ИИ-карта: бэкенд `/ai-map/apply`, при недоступности — локальный stub.
class AiMapService {
  AiMapService({ApiService? api, LocalAiMapEngine? local})
      : _api = api ?? ApiService(),
        _local = local ?? LocalAiMapEngine();

  final ApiService _api;
  final LocalAiMapEngine _local;

  Future<AiMapApplyResult> apply({
    required String message,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    Map<String, dynamic>? objectCard,
    String apartmentId = 'arthouse_project',
    String apartmentName = 'Мой объект',
    bool approved = false,
    bool forceBackend = false,
  }) async {
    if (!forceBackend) {
      try {
        final fromApi = await _applyViaApi(
          message: message,
          currentMap: currentMap,
          premiseRooms: premiseRooms,
          objectCard: objectCard,
          apartmentId: apartmentId,
          apartmentName: apartmentName,
          approved: approved,
        );
        return fromApi;
      } on ApiException catch (e) {
        if (e.statusCode != 0 && e.statusCode != 401) {
          rethrow;
        }
      } catch (_) {
        // offline / нет JWT — локальный stub
      }
    } else {
      return _applyViaApi(
        message: message,
        currentMap: currentMap,
        premiseRooms: premiseRooms,
        objectCard: objectCard,
        apartmentId: apartmentId,
        apartmentName: apartmentName,
        approved: approved,
      );
    }

    return _local.apply(
      message: message,
      currentMap: currentMap,
      premiseRooms: premiseRooms,
      apartmentId: apartmentId,
      apartmentName: apartmentName,
      approved: approved,
    );
  }

  Future<AiMapApplyResult> _applyViaApi({
    required String message,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    Map<String, dynamic>? objectCard,
    required String apartmentId,
    required String apartmentName,
    required bool approved,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'current_map': currentMap ?? <String, dynamic>{},
      'premise_rooms': premiseRooms ?? <Map<String, dynamic>>[],
      'object_card': objectCard,
      'apartment_id': apartmentId,
      'apartment_name': apartmentName,
      'approved': approved,
    };

    final raw = await _api.post(
      '/ai-map/apply',
      body: body,
      requireAuth: true,
    );

    if (raw is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Некорректный ответ ИИ-карты');
    }

    return AiMapApplyResult(
      replyText: raw['reply_text']?.toString() ?? '',
      unityMap: _asStringKeyMap(raw['unity_map']),
      unityMapPatch: raw['unity_map_patch'] is Map
          ? _asStringKeyMap(raw['unity_map_patch'])
          : null,
      focusRoomId: raw['focus_room_id']?.toString(),
      source: raw['source']?.toString() ?? 'api',
      patchApplied: raw['patch_applied'] == true,
    );
  }

  Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  /// ИИ-3 расстановка: список объектов от ai-vision → координаты на сетке Unity.
  Future<AiMapApplyResult> placeFromDetection({
    required List<AiVisionItem> items,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    String apartmentId = 'arthouse_project',
    String apartmentName = 'Мой объект',
    String? roomId,
    String? roomHint,
    bool keepExisting = true,
  }) async {
    final body = <String, dynamic>{
      'items': items.map((it) => it.toJson()).toList(),
      'current_map': currentMap ?? <String, dynamic>{},
      'premise_rooms': premiseRooms ?? <Map<String, dynamic>>[],
      'apartment_id': apartmentId,
      'apartment_name': apartmentName,
      if (roomId != null) 'room_id': roomId,
      if (roomHint != null) 'room_hint': roomHint,
      'keep_existing': keepExisting,
    };

    final raw = await _api.post(
      '/ai-map/place-from-detection',
      body: body,
      requireAuth: true,
    );
    if (raw is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: 500,
        message: 'Некорректный ответ ИИ-карты',
      );
    }

    return AiMapApplyResult(
      replyText: raw['reply_text']?.toString() ?? '',
      unityMap: _asStringKeyMap(raw['unity_map']),
      unityMapPatch: raw['unity_map_patch'] is Map
          ? _asStringKeyMap(raw['unity_map_patch'])
          : null,
      focusRoomId: raw['focus_room_id']?.toString(),
      source: raw['source']?.toString() ?? 'layout_solver',
      patchApplied: true,
    );
  }
}
