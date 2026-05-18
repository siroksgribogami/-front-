import '../models/marketplace_project.dart';
import 'api_service.dart';

/// Сервис проектов маркетплейса: карта в JSONB на бэкенде.
class ProjectService {
  final ApiService _api = ApiService();

  /// Черновик после опроса: `POST /projects` с `map_data`.
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
      'map_data': mapData,
    };

    final response = await _api.post(
      '/projects',
      body: apiBody,
      requireAuth: true,
    );
    return _projectFromApi(response);
  }

  /// Сохранение карты: `PATCH /projects/{id}/map-data`.
  Future<ProjectSummary> updateMapData(
    String projectId,
    Map<String, dynamic> mapData, {
    ProjectSummary? project,
  }) async {
    final id = int.tryParse(projectId);
    if (id == null) {
      return _localFallback(projectId, mapData, project: project);
    }

    final response = await _api.patch(
      '/projects/$id/map-data',
      body: {'map_data': mapData},
      requireAuth: true,
    );
    return _projectFromApi(response, fallbackMapData: mapData);
  }

  Future<List<ProjectSummary>> getMyProjects() async {
    final response = await _api.get(
      '/projects/my',
      requireAuth: true,
    );
    final list = response as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((item) => _projectFromApi(item))
        .toList();
  }

  ProjectSummary _projectFromApi(
    dynamic response, {
    Map<String, dynamic>? fallbackMapData,
  }) {
    final map = Map<String, dynamic>.from(response as Map);
    final mapData = (map['map_data'] as Map?)?.cast<String, dynamic>() ??
        fallbackMapData ??
        const <String, dynamic>{};
    return ProjectSummary(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      status: _statusLabel(map['status']),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      responsesCount: (map['responses_count'] as num?)?.toInt() ?? 0,
      mapData: mapData,
    );
  }

  ProjectSummary _localFallback(
    String projectId,
    Map<String, dynamic> mapData, {
    ProjectSummary? project,
  }) {
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

  String _statusLabel(dynamic status) {
    final raw = status?.toString().toLowerCase() ?? '';
    switch (raw) {
      case 'draft':
        return 'Черновик';
      case 'published':
        return 'Опубликован';
      case 'in_work':
        return 'В работе';
      case 'closed':
        return 'Закрыт';
      case 'archived':
        return 'Архив';
      default:
        return status?.toString() ?? '';
    }
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
