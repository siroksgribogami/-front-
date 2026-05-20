import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../config/app_theme.dart';
import '../../../services/unity/hosted_unity_bridge.dart';

/// Полноэкранный Unity WebGL внутри приложения (без внешнего браузера).
///
/// На Android: [AndroidWebViewControllerCreationParams], hybrid composition
/// (стабильнее WebGL, чем текстура по умолчанию), отключён жест для воспроизведения медиа,
/// системная кнопка «Назад» сначала откатывает историю WebView.
class HostedUnityWebGlScreen extends StatefulWidget {
  const HostedUnityWebGlScreen({
    super.key,
    required this.uri,
    this.initialMap,
    this.mapPatch,
    this.focusRoomId,
  });

  final Uri uri;

  /// Текущая карта проекта — уходит в Unity через ReceiveInitialMapJson.
  final Map<String, dynamic>? initialMap;

  /// Diff после ИИ (roomsUpsert, …); мержится перед отправкой в Unity.
  final Map<String, dynamic>? mapPatch;

  final String? focusRoomId;

  @override
  State<HostedUnityWebGlScreen> createState() => _HostedUnityWebGlScreenState();
}

class _HostedUnityWebGlScreenState extends State<HostedUnityWebGlScreen> {
  late final WebViewController _controller;
  var _pageLoading = true;
  var _progress = 0;
  String? _errorDescription;

  static WebViewController _createWebViewController() {
    if (!kIsWeb && WebViewPlatform.instance is AndroidWebViewPlatform) {
      final params =
          AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
        const PlatformWebViewControllerCreationParams(),
      );
      return WebViewController.fromPlatformCreationParams(params);
    }
    return WebViewController();
  }

  @override
  void initState() {
    super.initState();
    _controller = _createWebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1B1813))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pageLoading = true;
              _progress = 0;
              _errorDescription = null;
            });
          },
          onProgress: (int value) {
            if (!mounted) {
              return;
            }
            setState(() => _progress = value.clamp(0, 100));
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pageLoading = false;
              _progress = 100;
            });
            unawaited(_pushMapToUnity());
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pageLoading = false;
              _errorDescription =
                  error.description.isNotEmpty ? error.description : 'Ошибка загрузки';
            });
          },
        ),
      );

    unawaited(_applyAndroidTuningAndLoad());
  }

  Future<void> _applyAndroidTuningAndLoad() async {
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
    }
    await _controller.loadRequest(widget.uri);
  }

  Future<void> _pushMapToUnity() async {
    final map = widget.initialMap;
    if (map == null || map.isEmpty) {
      return;
    }
    final mapJson = jsonEncode(map);
    final script = buildHostedUnityInjectScript(
      mapJson: mapJson,
      patch: widget.mapPatch,
      focusRoomId: widget.focusRoomId,
    );
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('HostedUnity: inject map failed: $e');
    }
  }

  Future<void> _handleSystemBack(NavigatorState navigator) async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (!mounted) {
      return;
    }
    navigator.pop();
  }

  Widget _webViewSurface(BuildContext context) {
    if (!kIsWeb && WebViewPlatform.instance is AndroidWebViewPlatform) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
          PlatformWebViewWidgetCreationParams(
            controller: _controller.platform,
            layoutDirection: Directionality.of(context),
          ),
          displayWithHybridComposition: true,
        ),
      );
    }
    return WebViewWidget(controller: _controller);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        await _handleSystemBack(navigator);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text(
            '3D-карта',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await _controller.canGoBack()) {
                await _controller.goBack();
                return;
              }
              if (!mounted) {
                return;
              }
              navigator.pop();
            },
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _webViewSurface(context)),
            if (_pageLoading && _progress < 100)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: _progress > 0 ? _progress / 100.0 : null,
                ),
              ),
            if (_errorDescription != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _errorDescription!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
