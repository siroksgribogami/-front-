import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'ai_vision_service.dart';
import 'api_service.dart';
import 'local_ai_map_engine.dart';
import 'secure_storage_service.dart';

export 'local_ai_map_engine.dart' show AiMapApplyResult;

/// Smart Vision Map: фото → unity_map + детекция за один запрос.
class AiMapFromPhotoResult {
  final AiMapApplyResult placement;
  final AiVisionDetectResult detection;

  const AiMapFromPhotoResult({
    required this.placement,
    required this.detection,
  });
}

/// ИИ-карта: бэкенд `/ai-map/apply`, при недоступности — локальный stub.
class AiMapService {
  AiMapService({
    ApiService? api,
    LocalAiMapEngine? local,
    SecureStorageService? storage,
    http.Client? client,
  })  : _api = api ?? ApiService(),
        _local = local ?? LocalAiMapEngine(),
        _storage = storage ?? SecureStorageService(),
        _client = client ?? http.Client();

  final ApiService _api;
  final LocalAiMapEngine _local;
  final SecureStorageService _storage;
  final http.Client _client;

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

  /// Расстановка: список объектов vision → координаты на сетке Unity.
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

  /// Smart Vision Map — одна цепочка (см. docs/smart-vision-map-ru.md).
  Future<AiMapFromPhotoResult> placeFromPhoto({
    required File imageFile,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    String apartmentId = 'arthouse_project',
    String apartmentName = 'Мой объект',
    String? roomId,
    String? roomHint,
    bool keepExisting = true,
    bool forceLlm = false,
  }) async {
    try {
      return await _placeFromPhotoApi(
        imageFile: imageFile,
        currentMap: currentMap,
        premiseRooms: premiseRooms,
        apartmentId: apartmentId,
        apartmentName: apartmentName,
        roomId: roomId,
        roomHint: roomHint,
        keepExisting: keepExisting,
        forceLlm: forceLlm,
      );
    } on ApiException catch (e) {
      if (e.statusCode != 0 && e.statusCode != 401) rethrow;
    } catch (_) {
      // offline — два шага локально через vision + place (как раньше)
    }

    final vision = AiVisionService(storage: _storage, client: _client);
    final detection = await vision.detectFromFile(
      imageFile,
      roomHint: roomHint,
      forceLlm: forceLlm,
    );
    final placement = await placeFromDetection(
      items: detection.items.where((it) => it.isMapped).toList(),
      currentMap: currentMap,
      premiseRooms: premiseRooms,
      apartmentId: apartmentId,
      apartmentName: apartmentName,
      roomId: roomId,
      roomHint: detection.roomHint ?? roomHint,
      keepExisting: keepExisting,
    );
    return AiMapFromPhotoResult(placement: placement, detection: detection);
  }

  Future<AiMapFromPhotoResult> _placeFromPhotoApi({
    required File imageFile,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    required String apartmentId,
    required String apartmentName,
    String? roomId,
    String? roomHint,
    required bool keepExisting,
    required bool forceLlm,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/ai-map/from-photo');
    final request = http.MultipartRequest('POST', uri);
    final token = await _storage.read(key: ApiConfig.tokenKey);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    final bytes = await imageFile.readAsBytes();
    final name = imageFile.path.split(RegExp(r'[/\\]')).last;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name.isEmpty ? 'photo.jpg' : name,
      ),
    );
    request.fields['apartment_id'] = apartmentId;
    request.fields['apartment_name'] = apartmentName;
    request.fields['keep_existing'] = keepExisting.toString();
    request.fields['force_llm'] = forceLlm.toString();
    if (currentMap != null && currentMap.isNotEmpty) {
      request.fields['current_map'] = jsonEncode(currentMap);
    }
    if (premiseRooms != null && premiseRooms.isNotEmpty) {
      request.fields['premise_rooms'] = jsonEncode(premiseRooms);
    }
    if (roomId != null && roomId.isNotEmpty) request.fields['room_id'] = roomId;
    if (roomHint != null && roomHint.isNotEmpty) {
      request.fields['room_hint'] = roomHint;
    }

    final streamed = await _client
        .send(request)
        .timeout(ApiConfig.requestTimeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: 500,
        message: 'Некорректный ответ Smart Vision Map',
      );
    }

    final detRaw = raw['detection'];
    final detection = detRaw is Map<String, dynamic>
        ? AiVisionDetectResult.fromJson(detRaw)
        : AiVisionDetectResult(
            items: const [],
            source: raw['vision_source']?.toString() ?? 'api',
          );

    final placement = AiMapApplyResult(
      replyText: raw['reply_text']?.toString() ?? '',
      unityMap: _asStringKeyMap(raw['unity_map']),
      unityMapPatch: raw['unity_map_patch'] is Map
          ? _asStringKeyMap(raw['unity_map_patch'])
          : null,
      focusRoomId: raw['focus_room_id']?.toString(),
      source: raw['source']?.toString() ?? 'smart_vision_map',
      patchApplied: true,
    );
    return AiMapFromPhotoResult(placement: placement, detection: detection);
  }
}
