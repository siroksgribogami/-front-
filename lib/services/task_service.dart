import '../config/api_config.dart';
import 'api_service.dart';

/// Сервис задач (`/tasks`).
class TaskService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getTasks({
    int? apartmentId,
    bool assignedToMe = false,
    int skip = 0,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'assigned_to_me': '$assignedToMe',
      'skip': '$skip',
      'limit': '$limit',
    };
    if (apartmentId != null) {
      query['apartment_id'] = '$apartmentId';
    }

    final response = await _api.get(
      ApiConfig.tasks,
      queryParams: query,
      requireAuth: true,
    );
    return _asMapList(response);
  }

  Future<List<Map<String, dynamic>>> getMyTasks() async {
    final response = await _api.get(
      '${ApiConfig.tasks}/my',
      requireAuth: true,
    );
    return _asMapList(response);
  }

  Future<Map<String, dynamic>> getTaskById(int taskId) async {
    final response = await _api.get(
      '${ApiConfig.tasks}/$taskId',
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.tasks,
      body: data,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateTask(
    int taskId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(
      '${ApiConfig.tasks}/$taskId',
      body: data,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    int taskId,
    String status,
  ) async {
    final response = await _api.patch(
      '${ApiConfig.tasks}/$taskId/status',
      body: {'status': status},
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteTask(int taskId) async {
    await _api.delete(
      '${ApiConfig.tasks}/$taskId',
      requireAuth: true,
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic response) {
    final data = response as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
