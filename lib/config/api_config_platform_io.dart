import 'dart:io';

import 'api_config.dart';

/// Инициализация API под платформу. Вызывается из main() на мобильных/десктопе.
void initApiConfigForPlatform() {
  // Явное переопределение через flutter run/build:
  // --dart-define=API_BASE_URL=http://192.168.0.13:8000
  const apiFromDefine = String.fromEnvironment('API_BASE_URL');
  if (apiFromDefine.isNotEmpty) {
    ApiConfig.baseUrlOverride = apiFromDefine;
    return;
  }

  if (Platform.isAndroid) {
    // Эмулятор: 10.0.2.2 → ПК. Реальный телефон: --dart-define или adb reverse + 127.0.0.1:8000.
    ApiConfig.baseUrlOverride = 'http://10.0.2.2:8000';
  }
  // iOS/десктоп: оставляем 127.0.0.1 по умолчанию
}
