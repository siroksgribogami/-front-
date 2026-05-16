import '../models/marketplace_project.dart';
import 'api_service.dart';

/// Сервис проектов маркетплейса поверх REST API.
class ProjectService {
  final ApiService _api = ApiService();

  /// Черновик после опроса: `POST /projects` (тело как у бэка), карта — локально.
  Future<ProjectSummary> createDraftFromSurvey(
    Map<String, dynamic> payload,
  ) async {
    final mapData = Map<String, dynamic>.from(
      (payload['map_data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final apiBody = <String, dynamic>{
      'title': payload['title'],
      if (payload['work_type'] != null) 'work_type': payload['work_type'],
      if (payload['teaser'] != null) 'teaser': payload['teaser'],
      'full_spec': _fullSpecForApi(payload),
      'has_3d': mapData.isNotEmpty,
    };

    final response = await _api.post(
      '/projects',
      body: apiBody,
      requireAuth: true,
    );
    final fromApi = ProjectSummary.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    return ProjectSummary(
      id: fromApi.id,
      title: fromApi.title,
      status: fromApi.status,
      updatedAt: fromApi.updatedAt,
      responsesCount: fromApi.responsesCount,
      mapData: mapData,
    );
  }

  /// Карта проекта пока только в локальном кэше (на бэке нет PATCH /map).
  Future<ProjectSummary> updateMapData(
    String projectId,
    Map<String, dynamic> mapData, {
    ProjectSummary? project,
  }) async {
    final base = project;
    if (base != null) {
      return ProjectSummary(
        id: base.id,
        title: base.title,
        status: base.status,
        updatedAt: DateTime.now(),
        responsesCount: base.responsesCount,
        mapData: mapData,
      );
    }
    return ProjectSummary(
      id: projectId,
      title: '',
      status: 'draft',
      updatedAt: DateTime.now(),
      mapData: mapData,
    );
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

  String _fullSpecForApi(Map<String, dynamic> payload) {
    final base = payload['full_spec']?.toString().trim() ?? '';
    final parts = <String>[];
    void add(String label, Object? value) {
      if (value == null) return;
      parts.add('$label: $value');
    }

    add('property_type', payload['property_type']);
    add('total_area', payload['total_area']);
    add('ceiling_height', payload['ceiling_height']);
    add('floors_count', payload['floors_count']);
    add('rooms_count', payload['rooms_count']);
    add('house_floors', payload['house_floors']);

    if (parts.isEmpty) return base;
    final extra = parts.join(' | ');
    return base.isEmpty ? extra : '$base | $extra';
  }
}
