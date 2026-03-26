import '../config/api_config.dart';
import '../models/apartment.dart';
import 'api_service.dart';

/// Сервис для работы с квартирами
class ApartmentService {
  final ApiService _api = ApiService();

  /// Получить все квартиры пользователя
  Future<List<Apartment>> getMyApartments() async {
    final response = await _api.get(
      ApiConfig.apartmentsMy,
      requireAuth: true,
    );
    
    if (response is List) {
      return response.map((json) => Apartment.fromJson(json)).toList();
    }
    return [];
  }

  /// Получить квартиру по ID
  Future<Apartment> getApartment(int id) async {
    try {
      final response = await _api.get(
        '${ApiConfig.apartmentsMy}/$id',
        requireAuth: true,
      );
      return Apartment.fromJson(response);
    } catch (_) {
      // Совместимость с backend-веткой, где роут: /apartments/{id}
      final response = await _api.get(
        '/apartments/$id',
        requireAuth: true,
      );
      return Apartment.fromJson(response);
    }
  }

  /// Создать новую квартиру
  Future<Apartment> createApartment(ApartmentCreate data) async {
    try {
      final response = await _api.post(
        ApiConfig.apartmentsMy,
        body: data.toJson(),
        requireAuth: true,
      );
      return Apartment.fromJson(response);
    } catch (_) {
      // Совместимость с backend-веткой, где роут: POST /apartments/
      final response = await _api.post(
        '/apartments/',
        body: data.toJson(),
        requireAuth: true,
      );
      return Apartment.fromJson(response);
    }
  }

  /// Обновить квартиру
  Future<Apartment> updateApartment(int id, ApartmentUpdate data) async {
    try {
      final response = await _api.put(
        '${ApiConfig.apartmentsMy}/$id',
        body: data.toJson(),
        requireAuth: true,
      );
      return Apartment.fromJson(response);
    } catch (_) {
      final response = await _api.put(
        '/apartments/$id',
        body: data.toJson(),
        requireAuth: true,
      );
      return Apartment.fromJson(response);
    }
  }

  /// Удалить квартиру
  Future<void> deleteApartment(int id) async {
    try {
      await _api.delete(
        '${ApiConfig.apartmentsMy}/$id',
        requireAuth: true,
      );
    } catch (_) {
      await _api.delete(
        '/apartments/$id',
        requireAuth: true,
      );
    }
  }
}
