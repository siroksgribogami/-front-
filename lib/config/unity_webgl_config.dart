/// URL корня захостенного Unity WebGL (встраивается во встроенный WebView).
///
/// Переопределение при сборке:
/// `flutter run --dart-define=UNITY_WEBGL_BUILD_URL=https://your-host/build/`
class UnityWebGlConfig {
  UnityWebGlConfig._();

  static const String buildUrl = String.fromEnvironment(
    'UNITY_WEBGL_BUILD_URL',
    defaultValue: 'https://dry-bar-50f6.andreym67764.workers.dev/',
  );
}
