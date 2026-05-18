import 'local_estimate_engine.dart';

export 'local_estimate_engine.dart' show EstimateCompileResult;

/// Смета на клиенте: catalog_work_id + qty; цены из assets/data.
class EstimateService {
  final LocalEstimateEngine _engine = LocalEstimateEngine();

  Future<List<Map<String, dynamic>>> getCatalogForLlm() =>
      _engine.getCatalogForLlm();

  Future<EstimateCompileResult> compile({
    List<Map<String, dynamic>>? selections,
    String? message,
    double reservePercent = 12,
  }) =>
      _engine.compile(
        selections: selections,
        message: message,
        reservePercent: reservePercent,
      );
}
