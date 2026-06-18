import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/brand_runtime.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../config/brand_colors.dart';
import '../../../core/theme/brand_ui.dart';
import '../../../config/text_theme.dart';
import '../../../services/unity/hosted_unity_bridge.dart';

/// Полноэкранный Unity WebGL внутри приложения (без внешнего браузера).
class HostedUnityWebGlScreen extends StatefulWidget {
  const HostedUnityWebGlScreen({
    super.key,
    required this.uri,
    this.initialMap,
    this.mapPatch,
    this.focusRoomId,
    this.roomTitle = 'Кухня-гостиная',
    this.roomSubtitle = '3 комнаты · 28.4 м² · после ремонта',
  });

  final Uri uri;
  final Map<String, dynamic>? initialMap;
  final Map<String, dynamic>? mapPatch;
  final String? focusRoomId;
  final String roomTitle;
  final String roomSubtitle;

  @override
  State<HostedUnityWebGlScreen> createState() => _HostedUnityWebGlScreenState();
}

class _HostedUnityWebGlScreenState extends State<HostedUnityWebGlScreen> {
  late final WebViewController _controller;
  var _pageLoading = true;
  var _progress = 0;
  String? _errorDescription;
  int _activeTool = 0;

  static const _tools = ['Поворот', 'Этажи', 'Замер', 'Свет'];

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
      ..setBackgroundColor(BrandColors.needlesDeep)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _pageLoading = true;
              _progress = 0;
              _errorDescription = null;
            });
          },
          onProgress: (int value) {
            if (!mounted) return;
            setState(() => _progress = value.clamp(0, 100));
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _pageLoading = false;
              _progress = 100;
            });
            unawaited(_pushMapToUnity());
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
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
    if (map == null || map.isEmpty) return;
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
    if (!mounted) return;
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
    final topPad = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _handleSystemBack(Navigator.of(context));
      },
      child: Scaffold(
        backgroundColor: BrandColors.needlesDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _webViewSurface(context)),
            if (_pageLoading && _progress < 100)
              Positioned(
                top: topPad,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: _progress > 0 ? _progress / 100.0 : null,
                  color: BrandColors.clay,
                  backgroundColor: BrandColors.onNeedles.withOpacity(0.12),
                ),
              ),
            if (_pageLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: BrandColors.needlesDeep,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.clay,
                      value: _progress > 0 ? _progress / 100.0 : null,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: topPad + 12,
              left: 16,
              child: BrandIconButton(
                onPressed: () => _handleSystemBack(Navigator.of(context)),
                onDark: true,
                size: 40,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: BrandColors.onNeedles,
                ),
              ),
            ),
            Positioned(
              top: topPad + 12,
              right: 16,
              child: BrandGlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: BrandColors.needlesLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '100%',
                      style: BrandUi.monoLabel(
                        fontSize: 11,
                        color: BrandColors.dawn.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_tools.length, (i) {
                      final active = i == _activeTool;
                      return GestureDetector(
                        onTap: () => setState(() => _activeTool = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? BrandColors.clay
                                : BrandRuntime.card.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _tools[i],
                            style: BrandUi.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? BrandColors.onClay
                                  : BrandRuntime.needles,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: BrandRuntime.card.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_in_ar_outlined,
                          color: BrandRuntime.needles,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.roomTitle,
                                style: pochaevsk(
                                  fontSize: 17,
                                  color: BrandRuntime.ink,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.roomSubtitle,
                                style: BrandUi.inter(
                                  fontSize: 12,
                                  color: BrandRuntime.ink.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandRuntime.needles,
                            foregroundColor: BrandColors.onNeedles,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BrandUi.buttonRadius,
                            ),
                          ),
                          child: Text(
                            'Поделиться',
                            style: BrandUi.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.onNeedles,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_errorDescription != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: BrandRuntime.ink.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _errorDescription!,
                      style: BrandUi.inter(
                        fontSize: 13,
                        color: BrandColors.onNeedles,
                      ),
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
