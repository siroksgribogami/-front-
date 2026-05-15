import '../config/api_config.dart';
import 'api_service.dart';

/// Сервис снимков карты (`/snapshots`).
class SnapshotService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getLatestSnapshot(int apartmentId) async {
    final response = await _api.get(
      '${ApiConfig.snapshots}/apartments/$apartmentId/latest',
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> saveSnapshot(
    int apartmentId,
    Map<String, dynamic> snapshotData,
  ) async {
    final response = await _api.post(
      '${ApiConfig.snapshots}/apartments/$apartmentId/save',
      body: snapshotData,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateFurniturePosition({
    required int apartmentId,
    required int roomId,
    required String furnitureId,
    required List<double> newPosition,
  }) async {
    final response = await _api.patch(
      '${ApiConfig.snapshots}/apartments/$apartmentId/furniture'
      '?room_id=$roomId&furniture_id=$furnitureId',
      body: {'new_position': newPosition},
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> getSnapshotHistory(
    int apartmentId, {
    int limit = 50,
  }) async {
    final response = await _api.get(
      '${ApiConfig.snapshots}/apartments/$apartmentId/history',
      queryParams: {'limit': '$limit'},
      requireAuth: true,
    );
    final data = response as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
