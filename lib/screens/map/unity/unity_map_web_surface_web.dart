// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../../models/unity/unity_map_contract.dart';

class UnityMapWebController {
  _UnityMapWebSurfaceState? _state;
  final Completer<void> _attached = Completer<void>();

  void _attach(_UnityMapWebSurfaceState state) {
    _state = state;
    if (!_attached.isCompleted) {
      _attached.complete();
    }
  }

  void _detach(_UnityMapWebSurfaceState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  Future<_UnityMapWebSurfaceState?> _getState() async {
    if (_state != null) {
      return _state;
    }

    try {
      await _attached.future.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      return null;
    }
    return _state;
  }

  Future<bool> isUnityAvailable() async {
    final state = await _getState();
    if (state == null) {
      return false;
    }
    return state.waitForAvailability();
  }

  Future<void> initializeEditor(UnityApartmentMapData payload) async {
    final state = await _getState();
    await state?.postCommand(
      'initializeEditor',
      payload: payload.toJsonString(),
    );
  }

  /// Частичное обновление: diff `{ roomsUpsert, tasksUpsert, taskIdsRemove }`.
  Future<void> applyMapPatch(Map<String, dynamic> patch) async {
    final state = await _getState();
    await state?.postCommand(
      'applyMapPatch',
      payload: jsonEncode(patch),
    );
  }

  Future<void> focusRoom(String roomId) async {
    final state = await _getState();
    await state?.postCommand('focusRoom', roomId: roomId);
  }

  Future<void> undo() async {
    final state = await _getState();
    await state?.postCommand('undo');
  }

  Future<void> redo() async {
    final state = await _getState();
    await state?.postCommand('redo');
  }

  Future<String?> requestSnapshot() async {
    final state = await _getState();
    return state?.requestSnapshot();
  }

  Future<void> showOverview(bool enabled) async {
    final state = await _getState();
    await state?.postCommand('showOverview', payload: enabled ? 'true' : 'false');
  }

  String? get lastStatusMessage => _state?.lastStatusMessage;
}

class UnityMapWebSurface extends StatefulWidget {
  const UnityMapWebSurface({super.key, required this.controller});

  final UnityMapWebController controller;

  @override
  State<UnityMapWebSurface> createState() => _UnityMapWebSurfaceState();
}

class _UnityMapWebSurfaceState extends State<UnityMapWebSurface> {
  static int _viewIdCounter = 0;

  late final String _viewType;
  late final html.IFrameElement _iframe;
  StreamSubscription<html.MessageEvent>? _subscription;
  final Completer<bool> _availabilityCompleter = Completer<bool>();

  bool _unityAvailable = false;
  String? _lastSnapshotJson;
  String? lastStatusMessage;
  Completer<String?>? _snapshotCompleter;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _viewType = 'arthouse-unity-web-surface-${_viewIdCounter++}';
    _iframe = html.IFrameElement()
      ..src = 'unity_bridge_host.html'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'autoplay; fullscreen; clipboard-read; clipboard-write';

    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int _) => _iframe);
    _subscription = html.window.onMessage.listen(_handleMessage);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    widget.controller._detach(this);
    super.dispose();
  }

  Future<bool> waitForAvailability() async {
    if (_availabilityCompleter.isCompleted) {
      return _unityAvailable;
    }

    try {
      return await _availabilityCompleter.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
    } on TimeoutException {
      return false;
    }
  }

  Future<void> postCommand(
    String type, {
    String? payload,
    String? roomId,
  }) async {
    final message = {
      'source': 'arthouse-flutter-web',
      'type': type,
      'payload': payload,
      'roomId': roomId,
    };
    _iframe.contentWindow?.postMessage(jsonEncode(message), '*');
  }

  Future<String?> requestSnapshot() async {
    _snapshotCompleter = Completer<String?>();
    await postCommand('requestSnapshot');
    try {
      return await _snapshotCompleter!.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => _lastSnapshotJson,
      );
    } on TimeoutException {
      return _lastSnapshotJson;
    }
  }

  void _handleMessage(html.MessageEvent event) {
    if (event.source != _iframe.contentWindow) {
      return;
    }

    final data = event.data;
    if (data is! String) {
      return;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException {
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      return;
    }

    if (decoded['source'] != 'arthouse-unity-webgl') {
      return;
    }

    final type = decoded['type'] as String? ?? '';
    switch (type) {
      case 'availability':
        _unityAvailable = decoded['available'] as bool? ?? false;
        lastStatusMessage = decoded['message'] as String?;
        if (!_availabilityCompleter.isCompleted) {
          _availabilityCompleter.complete(_unityAvailable);
        }
        break;
      case 'unityReady':
        _unityAvailable = true;
        lastStatusMessage =
            decoded['message'] as String? ?? 'Unity WebGL bridge готов.';
        if (!_availabilityCompleter.isCompleted) {
          _availabilityCompleter.complete(true);
        }
        break;
      case 'snapshot':
        final snapshotJson = decoded['snapshotJson'] as String?;
        if (snapshotJson != null && snapshotJson.isNotEmpty) {
          _lastSnapshotJson = snapshotJson;
        }
        if (_snapshotCompleter != null && !_snapshotCompleter!.isCompleted) {
          _snapshotCompleter!.complete(_lastSnapshotJson);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
