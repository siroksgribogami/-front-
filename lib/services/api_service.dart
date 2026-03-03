import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Исключение API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

/// Базовый сервис для работы с API
class ApiService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Получить сохранённый токен
  Future<String?> getToken() async {
    return _storage.read(key: ApiConfig.tokenKey);
  }

  /// Сохранить токен
  Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConfig.tokenKey, value: token);
  }

  /// Удалить токен
  Future<void> deleteToken() async {
    await _storage.delete(key: ApiConfig.tokenKey);
  }

  /// Проверить, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Получить заголовки для запроса
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Выполнить GET запрос
  Future<dynamic> get(
    String endpoint, {
    bool requireAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Нет подключения к интернету',
      );
    }
  }

  /// Выполнить POST запрос
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Нет подключения к интернету',
      );
    }
  }

  /// Выполнить PUT запрос
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Нет подключения к интернету',
      );
    }
  }

  /// Выполнить DELETE запрос
  Future<dynamic> delete(
    String endpoint, {
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Нет подключения к интернету',
      );
    }
  }

  /// Обработать ответ сервера
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = 'Произошла ошибка';
    dynamic details;

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map) {
        message = data['detail'] ?? message;
        details = data;
      }
    } catch (_) {}

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      details: details,
    );
  }
}
