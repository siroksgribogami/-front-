// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'apartment_scene_models.dart';

class ApartmentSceneView extends StatefulWidget {
  const ApartmentSceneView({
    super.key,
    required this.payload,
    required this.onRoomTap,
  });

  final ApartmentScenePayload payload;
  final ValueChanged<int> onRoomTap;

  @override
  State<ApartmentSceneView> createState() => _ApartmentSceneViewState();
}

class _ApartmentSceneViewState extends State<ApartmentSceneView> {
  static int _counter = 0;

  late final String _viewType;
  late final String _sceneId;
  late final html.IFrameElement _iframe;
  StreamSubscription<html.MessageEvent>? _messageSub;
  Timer? _postTimer;

  @override
  void initState() {
    super.initState();
    final suffix = _counter++;
    _sceneId = 'arthouse_scene_$suffix';
    _viewType = 'arthouse-scene-view-$suffix';
    _iframe = html.IFrameElement()
      ..src = 'apartment_scene.html?sceneId=$_sceneId'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'transparent';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _iframe);

    _iframe.onLoad.listen((_) => _postScene());
    _messageSub = html.window.onMessage.listen(_handleMessage);
  }

  @override
  void didUpdateWidget(covariant ApartmentSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _postScene();
  }

  @override
  void dispose() {
    _postTimer?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }

  void _handleMessage(html.MessageEvent event) {
    final data = event.data;
    if (data is! String) return;
    final decoded = jsonDecode(data);
    if (decoded is! Map) return;
    if (decoded['source'] != 'arthouse-scene') return;
    if (decoded['sceneId'] != _sceneId) return;
    if (decoded['type'] == 'roomTap') {
      final index = decoded['roomIndex'];
      if (index is int) {
        widget.onRoomTap(index);
      }
    }
  }

  void _postScene() {
    _postTimer?.cancel();
    _postTimer = Timer(const Duration(milliseconds: 60), () {
      final message = {
        'type': 'renderScene',
        'sceneId': _sceneId,
        'payload': widget.payload.toJson(),
      };
      _iframe.contentWindow?.postMessage(jsonEncode(message), '*');
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
