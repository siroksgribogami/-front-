import '../config/api_config.dart';
import 'api_service.dart';

/// Сервис комнат (`/apartments/{id}/rooms`, `/rooms/{id}`).
class RoomService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getRoomsByApartment(int apartmentId) async {
    final response = await _api.get(
      '${ApiConfig.apartments}/$apartmentId/rooms',
      requireAuth: true,
    );
    final data = response as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createRoom(
    int apartmentId,
    Map<String, dynamic> roomData,
  ) async {
    final response = await _api.post(
      '${ApiConfig.apartments}/$apartmentId/rooms',
      body: roomData,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> getRoomById(int roomId) async {
    final response = await _api.get(
      '${ApiConfig.rooms}/$roomId',
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateRoom(
    int roomId,
    Map<String, dynamic> roomData,
  ) async {
    final response = await _api.put(
      '${ApiConfig.rooms}/$roomId',
      body: roomData,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteRoom(int roomId) async {
    await _api.delete(
      '${ApiConfig.rooms}/$roomId',
      requireAuth: true,
    );
  }
}
