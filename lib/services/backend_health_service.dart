import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/backend_routes.dart';

/// Лёгкая проверка доступности бэкенда без правок в `art_back`.
/// `GET {baseUrl}/health` — см. `art_back/app/main.py`.
class BackendHealthService {
  BackendHealthService._();

  static Future<bool> ping({Duration timeout = const Duration(seconds: 4)}) async {
    final uri = Uri.parse('${ApiConfig.rootBaseUrl}${BackendRoutes.health}');
    try {
      final response = await http.get(uri).timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
