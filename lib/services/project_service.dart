import '../models/marketplace_project.dart';
import 'api_service.dart';

/// Сервис проектов маркетплейса поверх REST API.
class ProjectService {
  final ApiService _api = ApiService();

  Future<ProjectSummary> createDraftFromSurvey(
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.post(
      '/projects/from-survey',
      body: payload,
      requireAuth: true,
    );
    return ProjectSummary.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<ProjectSummary> updateMapData(
    String projectId,
    Map<String, dynamic> mapData,
  ) async {
    final response = await _api.patch(
      '/projects/${int.tryParse(projectId) ?? 0}/map',
      body: {'map_data': mapData},
      requireAuth: true,
    );
    return ProjectSummary.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<ProjectSummary>> getMyProjects() async {
    final response = await _api.get(
      '/projects/my',
      requireAuth: true,
    );
    final list = response as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((item) => ProjectSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
