import 'local_ai_map_engine.dart';

export 'local_ai_map_engine.dart' show AiMapApplyResult;

/// ИИ-карта на клиенте (без бэкенда): патч только после approved.
class AiMapService {
  final LocalAiMapEngine _engine = LocalAiMapEngine();

  Future<AiMapApplyResult> apply({
    required String message,
    Map<String, dynamic>? currentMap,
    List<Map<String, dynamic>>? premiseRooms,
    Map<String, dynamic>? objectCard,
    String apartmentId = 'arthouse_project',
    String apartmentName = 'Мой объект',
    bool approved = false,
  }) async {
    return _engine.apply(
      message: message,
      currentMap: currentMap,
      premiseRooms: premiseRooms,
      apartmentId: apartmentId,
      apartmentName: apartmentName,
      approved: approved,
    );
  }
}
