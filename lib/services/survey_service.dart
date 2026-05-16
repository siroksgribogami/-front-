import '../config/api_config.dart';
import 'api_service.dart';

/// Сервис опросов (`/surveys`).
class SurveyService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _api.get(
      ApiConfig.surveysDashboard,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> getMySurveys() async {
    final response = await _api.get(
      ApiConfig.surveys,
      requireAuth: true,
    );
    return _asMapList(response);
  }

  Future<Map<String, dynamic>> getLatestSurvey() async {
    final response = await _api.get(
      ApiConfig.surveysLatest,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> getSurveyById(int surveyId) async {
    final response = await _api.get(
      '/$surveyId',
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> createSurvey(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.surveys,
      body: data,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateSurvey(
    int surveyId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(
      '/$surveyId',
      body: data,
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateSurveyStep(
    int surveyId, {
    required Map<String, dynamic> stepData,
    required int completionPercentage,
  }) async {
    final response = await _api.patch(
      '/$surveyId/step',
      body: {
        'step_data': stepData,
        'completion_percentage': completionPercentage,
      },
      requireAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteSurvey(int surveyId) async {
    await _api.delete(
      '/$surveyId',
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
