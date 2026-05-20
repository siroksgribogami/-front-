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
