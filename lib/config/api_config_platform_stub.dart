import 'api_config.dart';

/// Инициализация API для Web.
/// Поддержка: flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
void initApiConfigForPlatform() {
  const apiFromDefine = String.fromEnvironment('API_BASE_URL');
  if (apiFromDefine.isNotEmpty) {
    ApiConfig.baseUrlOverride = apiFromDefine;
  }
}
