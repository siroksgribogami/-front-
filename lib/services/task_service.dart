import '../config/api_config.dart';
import '../models/task.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _api = ApiService();

  Future<List<TaskItem>> getTasks({int? apartmentId, String? status}) async {
    final query = <String, String>{};
    if (apartmentId != null) query['apartment_id'] = '$apartmentId';
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _api.get(
      ApiConfig.tasks,
      requireAuth: true,
      queryParams: query.isEmpty ? null : query,
    );
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map((json) => TaskItem.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<TaskItem> createTask({
    required int apartmentId,
    required String title,
    String? description,
    int priority = 1,
    DateTime? dueDate,
  }) async {
    final response = await _api.post(
      '${ApiConfig.tasks}/$apartmentId',
      requireAuth: true,
      body: {
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
      },
    );
    return TaskItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<TaskItem> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    final response = await _api.put(
      '${ApiConfig.tasks}/$taskId',
      requireAuth: true,
      body: {'status': status},
    );
    return TaskItem.fromJson(Map<String, dynamic>.from(response as Map));
  }
}

