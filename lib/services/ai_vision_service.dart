import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../config/api_config.dart';
import 'api_service.dart';

/// Один объект, который ИИ-2 разглядел на фото.
class AiVisionItem {
  const AiVisionItem({
    required this.label,
    this.templateId,
    this.displayName,
    this.category,
    this.confidence = 0.5,
    this.notes = '',
  });

  final String label;
  final String? templateId;
  final String? displayName;
  final String? category;
  final double confidence;
  final String notes;

  bool get isMapped => templateId != null && templateId!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'label': label,
        if (templateId != null) 'templateId': templateId,
        if (displayName != null) 'displayName': displayName,
        if (category != null) 'category': category,
        'confidence': confidence,
        'notes': notes,
      };

  factory AiVisionItem.fromJson(Map<String, dynamic> json) => AiVisionItem(
        label: (json['label'] ?? '').toString(),
        templateId: json['templateId']?.toString(),
        displayName: json['displayName']?.toString(),
        category: json['category']?.toString(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        notes: (json['notes'] ?? '').toString(),
      );
}

class AiVisionDetectResult {
  const AiVisionDetectResult({
    required this.items,
    this.roomHint,
    this.notes = '',
    this.source = 'stub',
  });

  final List<AiVisionItem> items;
  final String? roomHint;
  final String notes;
  final String source;

  factory AiVisionDetectResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    return AiVisionDetectResult(
      items: raw
          .whereType<Map>()
          .map((e) => AiVisionItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      roomHint: json['room_hint']?.toString(),
      notes: (json['notes'] ?? '').toString(),
      source: (json['source'] ?? 'stub').toString(),
    );
  }
}

/// Результат «геометрии с фото»: размеры комнаты + карта с реальными позициями.
///
/// Бэкенд: `POST /ai-vision/geometry-from-photo` (YOLO + метрическая глубина +
/// маскировка окон + снап коллизий, см. docs/room-geometry-rnd-ru.md).
class AiGeometryResult {
  const AiGeometryResult({
    required this.unityMap,
    required this.geometry,
    this.detected = 0,
    this.placed = 0,
    this.snapped = 0,
  });

  /// Готовая карта комнаты (формат unity_map: rooms[].furniture[] с gridPosition).
  final Map<String, dynamic> unityMap;

  /// Оценки размеров: far_wall_m, visible_width_m, suggested_min_gridSize и т.п.
  final Map<String, dynamic> geometry;

  final int detected;
  final int placed;
  final int snapped;

  Map<String, dynamic>? get room {
    final rooms = (unityMap['rooms'] as List?) ?? const [];
    return rooms.isNotEmpty ? (rooms.first as Map).cast<String, dynamic>() : null;
  }

  List<Map<String, dynamic>> get furniture {
    final r = room;
    final raw = (r?['furniture'] as List?) ?? const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// «≈ Ш×Г м» по gridSize (клетка 0.5 м) — для подписи в UI.
  String get sizeLabel {
    final grid = (room?['gridSize'] as Map?)?.cast<String, dynamic>();
    if (grid == null) return '';
    final w = ((grid['x'] as num?) ?? 0) * 0.5;
    final d = ((grid['y'] as num?) ?? 0) * 0.5;
    return '≈ ${w.toStringAsFixed(1)} × ${d.toStringAsFixed(1)} м (не меньше)';
  }

  factory AiGeometryResult.fromJson(Map<String, dynamic> json) =>
      AiGeometryResult(
        unityMap: (json['unity_map'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
        geometry: (json['geometry'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
        detected: (json['detected'] as num?)?.toInt() ?? 0,
        placed: (json['placed'] as num?)?.toInt() ?? 0,
        snapped: (json['snapped'] as num?)?.toInt() ?? 0,
      );
}

/// ИИ-2: фото → объекты мебели + room_hint.
class AiVisionService {
  AiVisionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AiVisionDetectResult> detectFromFile(
    File file, {
    String? roomHint,
    bool forceLlm = false,
  }) async {
    final bytes = await file.readAsBytes();
    final segments = file.path.split(RegExp(r'[\\/]'));
    final filename = segments.isNotEmpty ? segments.last : 'photo.jpg';
    return detectFromBytes(
      bytes,
      filename: filename,
      mime: _guessMime(filename),
      roomHint: roomHint,
      forceLlm: forceLlm,
    );
  }

  Future<AiVisionDetectResult> detectFromBytes(
    List<int> bytes, {
    String filename = 'photo.jpg',
    String mime = 'image/jpeg',
    String? roomHint,
    bool forceLlm = false,
  }) async {
    final request = await _buildRequest(roomHint: roomHint, forceLlm: forceLlm);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _parseMime(mime),
      ),
    );
    return _send(request);
  }

  Future<AiVisionDetectResult> detectFromUrl(
    String imageUrl, {
    String? roomHint,
    bool forceLlm = false,
  }) async {
    final request = await _buildRequest(roomHint: roomHint, forceLlm: forceLlm);
    request.fields['image_url'] = imageUrl;
    return _send(request);
  }

  /// Геометрия комнаты и позиции мебели по фото (нейросеть глубины —
  /// дольше обычного распознавания, до ~20 с на CPU сервера).
  static const Duration _geometryTimeout = Duration(seconds: 90);

  Future<AiGeometryResult> geometryFromPhoto(
    List<int> bytes, {
    String filename = 'room.jpg',
    String mime = 'image/jpeg',
    String? roomId,
    double? fov,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBaseUrl}/ai-vision/geometry-from-photo',
    );
    final request = http.MultipartRequest('POST', uri);
    final token = await _storage.read(key: ApiConfig.tokenKey);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    if (roomId != null && roomId.isNotEmpty) {
      request.fields['room_id'] = roomId;
    }
    if (fov != null) {
      request.fields['fov'] = fov.toString();
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _parseMime(mime),
      ),
    );

    try {
      final streamed = await _client.send(request).timeout(_geometryTimeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return AiGeometryResult.fromJson(data);
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Некорректный ответ анализа фото',
        );
      }
      String message = 'Не удалось построить комнату по фото';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['detail'] is String) {
          message = data['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(statusCode: response.statusCode, message: message);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Анализ фото занял слишком долго — попробуйте ещё раз.',
      );
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Сервер недоступен.');
    } on http.ClientException {
      throw ApiException(statusCode: 0, message: 'Сервер недоступен.');
    }
  }

  Future<http.MultipartRequest> _buildRequest({
    String? roomHint,
    bool forceLlm = false,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBaseUrl}/ai-vision/detect-furniture',
    );
    final request = http.MultipartRequest('POST', uri);
    final token = await _storage.read(key: ApiConfig.tokenKey);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    if (roomHint != null && roomHint.isNotEmpty) {
      request.fields['room_hint'] = roomHint;
    }
    if (forceLlm) {
      request.fields['force_llm'] = 'true';
    }
    return request;
  }

  Future<AiVisionDetectResult> _send(http.MultipartRequest request) async {
    try {
      final streamed =
          await _client.send(request).timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Сервер не ответил вовремя.',
      );
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'Сервер недоступен.');
    } on http.ClientException {
      throw ApiException(statusCode: 0, message: 'Сервер недоступен.');
    }
  }

  AiVisionDetectResult _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        return AiVisionDetectResult.fromJson(data);
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Некорректный ответ ИИ-зрения',
      );
    }
    String message = 'Не удалось распознать фото';
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['detail'] is String) {
        message = data['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(statusCode: response.statusCode, message: message);
  }

  MediaType? _parseMime(String mime) {
    final parts = mime.split('/');
    if (parts.length != 2) return null;
    return MediaType(parts[0], parts[1]);
  }

  String _guessMime(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
