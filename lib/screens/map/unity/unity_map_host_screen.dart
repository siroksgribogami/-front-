import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_theme.dart';
import '../../../models/unity/unity_map_contract.dart';
import '../../../services/unity/unity_map_bridge_service.dart';
import '../../../services/unity/unity_map_desktop_service.dart';
import 'unity_map_web_surface.dart';

class UnityMapHostResult {
  const UnityMapHostResult({
    required this.map,
    required this.activeRoomId,
    required this.snapshotJson,
  });

  final UnityApartmentMapData map;
  final String activeRoomId;
  final String snapshotJson;
}

class UnityMapHostScreen extends StatefulWidget {
  const UnityMapHostScreen({
    super.key,
    required this.initialMap,
    required this.initialRoomId,
  });

  final UnityApartmentMapData initialMap;
  final String initialRoomId;

  @override
  State<UnityMapHostScreen> createState() => _UnityMapHostScreenState();
}

class _UnityMapHostScreenState extends State<UnityMapHostScreen> {
  final UnityMapBridgeService _bridge = UnityMapBridgeService.instance;
  final UnityMapDesktopService _desktopBridge = UnityMapDesktopService.instance;
  final UnityMapWebController _webBridge = UnityMapWebController();

  bool _unityAvailable = false;
  bool _isSending = false;
  String _activeRoomId = '';
  String? _snapshotJson;
  UnityDesktopSessionInfo? _desktopSessionInfo;
  late UnityApartmentMapData _workingMap;

  @override
  void initState() {
    super.initState();
    _activeRoomId = widget.initialRoomId.isNotEmpty
        ? widget.initialRoomId
        : (widget.initialMap.rooms.isNotEmpty
            ? widget.initialMap.rooms.first.roomId
            : '');
    _workingMap = widget.initialMap;
    _bootstrap();
  }

  bool get _canRenderAndroidHost =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _isWebHost => kIsWeb;

  Future<void> _bootstrap() async {
    if (_isWebHost) {
      final available = await _webBridge.isUnityAvailable();
      if (!mounted) {
        return;
      }

      setState(() {
        _unityAvailable = available;
      });

      await _pushInitialMap();
      return;
    }

    if (_isWindowsDesktop) {
      final sessionInfo = await _desktopBridge.startSession(
        map: widget.initialMap,
        roomId: _activeRoomId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _desktopSessionInfo = sessionInfo;
      });

      await _requestSnapshot();
      return;
    }

    final available = await _bridge.isUnityAvailable();
    if (!mounted) {
      return;
    }

    setState(() {
      _unityAvailable = available;
    });

    await _pushInitialMap();
  }

  Future<void> _pushInitialMap() async {
    setState(() => _isSending = true);
    if (_isWebHost) {
      await _webBridge.initializeEditor(_workingMap);
      if (_activeRoomId.isNotEmpty) {
        await _webBridge.focusRoom(_activeRoomId);
      }
    } else if (_isWindowsDesktop) {
      await _desktopBridge.initializeEditor(_workingMap, roomId: _activeRoomId);
      if (_activeRoomId.isNotEmpty) {
        await _desktopBridge.focusRoom(_activeRoomId);
      }
    } else {
      await _bridge.initializeEditor(_workingMap);
      if (_activeRoomId.isNotEmpty) {
        await _bridge.focusRoom(_activeRoomId);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _isSending = false);
  }

  Future<void> _requestSnapshot() async {
    final json = _isWebHost
        ? await _webBridge.requestSnapshot()
        : _isWindowsDesktop
            ? await _desktopBridge.requestSnapshot()
            : await _bridge.requestSnapshot();
    if (!mounted) {
      return;
    }

    UnityApartmentMapData parsedMap = _workingMap;
    if (json != null && json.isNotEmpty) {
      try {
        parsedMap = UnityApartmentMapData.fromJsonString(json);
      } on FormatException {
        parsedMap = _workingMap;
      }
    }

    setState(() {
      _snapshotJson = json;
      _workingMap = parsedMap;
    });
  }

  Future<void> _focusRoom(String roomId) async {
    setState(() => _activeRoomId = roomId);
    if (_isWebHost) {
      await _webBridge.focusRoom(roomId);
      return;
    }
    if (_isWindowsDesktop) {
      await _desktopBridge.focusRoom(roomId);
      return;
    }
    await _bridge.focusRoom(roomId);
  }

  Future<void> _undo() async {
    if (_isWebHost) {
      await _webBridge.undo();
      return;
    }
    if (_isWindowsDesktop) {
      await _desktopBridge.undo();
      return;
    }
    await _bridge.undo();
  }

  Future<void> _redo() async {
    if (_isWebHost) {
      await _webBridge.redo();
      return;
    }
    if (_isWindowsDesktop) {
      await _desktopBridge.redo();
      return;
    }
    await _bridge.redo();
  }

  Future<void> _launchDesktopSession() async {
    final sessionInfo = await _desktopBridge.startSession(
      map: _workingMap,
      roomId: _activeRoomId,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _desktopSessionInfo = sessionInfo;
    });
  }

  void _applyToFrontend() {
    Navigator.pop(
      context,
      UnityMapHostResult(
        map: _workingMap,
        activeRoomId: _activeRoomId,
        snapshotJson: _snapshotJson ?? _workingMap.toJsonString(),
      ),
    );
  }

  String get _statusMessage {
    if (_isWebHost) {
      return _unityAvailable
          ? 'Unity WebGL подключен. Chrome на ПК работает через iframe bridge и postMessage.'
          : 'Unity WebGL build пока не найден. Экран уже готов к Chrome/ПК, но нужен экспорт в art_front/web/unity_build.';
    }

    if (_canRenderAndroidHost) {
      return _unityAvailable
          ? 'Unity runtime подключен. Экран работает с реальным встроенным Unity Player.'
          : 'Unity runtime пока не подключен. JSON-контракт и Android host уже готовы, но до экспорта unityLibrary будет показан placeholder.';
    }

    if (_isWindowsDesktop) {
      if (_desktopSessionInfo?.isAvailable == true) {
        return 'Unity desktop найден. Flutter запускает отдельное Unity-окно и синхронизируется с ним через JSON bridge.';
      }
      return 'Unity desktop player пока не найден. Flutter Windows уже готов, но нужен .exe в map/Builds/Windows.';
    }

    return 'На этой платформе доступен только snapshot-режим без запуска Unity runtime.';
  }

  String? get _statusHint {
    if (_isWebHost) {
      return _webBridge.lastStatusMessage ??
          'Ожидается Unity WebGL export: web/unity_build/Build/ARTHOUSEMap.loader.js';
    }
    if (_isWindowsDesktop) {
      return _desktopSessionInfo?.executablePath ??
          _desktopSessionInfo?.message;
    }
    return null;
  }

  String get _bridgeChipLabel {
    if (_isWebHost) {
      return _unityAvailable ? 'WebGL bridge готов' : 'WebGL build не найден';
    }
    if (_canRenderAndroidHost) {
      return _unityAvailable ? 'Bridge активен' : 'Bridge еще не подключен';
    }
    if (_isWindowsDesktop) {
      return _desktopSessionInfo?.isAvailable == true
          ? 'Desktop bridge готов'
          : 'Unity exe не найден';
    }
    return 'Snapshot режим';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Unity карта',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          TextButton.icon(
            onPressed: _applyToFrontend,
            icon: const Icon(Icons.save_alt_rounded,
                color: AppTheme.primaryColor),
            label: const Text(
              'Применить',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusCard(
                message: _statusMessage,
                hint: _statusHint,
                isSending: _isSending,
              ),
              if (_isWindowsDesktop) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _launchDesktopSession,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(
                      _desktopSessionInfo?.isAvailable == true
                          ? 'Перезапустить Unity Desktop'
                          : 'Проверить и запустить Unity Desktop',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pushInitialMap,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_isWebHost
                          ? 'Отправить в Unity WebGL'
                          : _isWindowsDesktop
                              ? 'Отправить в Unity Desktop'
                              : 'Отправить в Unity'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _requestSnapshot,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Снять snapshot'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _undo,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Отменить'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _redo,
                      icon: const Icon(Icons.redo_rounded),
                      label: const Text('Вернуть'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppTheme.warmGrey.withOpacity(0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Связь с фронтом',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'После нажатия "Применить" текущий snapshot Unity вернется в экран карты и обновит комнаты и задачи во Flutter.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryChip(
                            label: '${_workingMap.rooms.length} комнат'),
                        _SummaryChip(
                            label: '${_workingMap.tasks.length} задач'),
                        _SummaryChip(label: _bridgeChipLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _UnitySurfaceCard(
                        roomId: _activeRoomId,
                        enabled: _canRenderAndroidHost,
                        isWebHost: _isWebHost,
                        isWindowsDesktop: _isWindowsDesktop,
                        webController: _webBridge,
                        executablePath: _desktopSessionInfo?.executablePath,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppTheme.warmGrey.withOpacity(0.35)),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _snapshotJson ?? widget.initialMap.toJsonString(),
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.message,
    required this.isSending,
    this.hint,
  });

  final String message;
  final bool isSending;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статус интеграции',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              hint!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          if (isSending) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class _UnitySurfaceCard extends StatelessWidget {
  const _UnitySurfaceCard({
    required this.roomId,
    required this.enabled,
    required this.isWebHost,
    required this.isWindowsDesktop,
    required this.webController,
    this.executablePath,
  });

  final String roomId;
  final bool enabled;
  final bool isWebHost;
  final bool isWindowsDesktop;
  final UnityMapWebController webController;
  final String? executablePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.warmGrey.withOpacity(0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: isWebHost
            ? UnityMapWebSurface(controller: webController)
            : enabled
                ? AndroidView(
                    viewType: UnityMapBridgeService.platformViewType,
                    creationParams: {'roomId': roomId},
                    creationParamsCodec: const StandardMessageCodec(),
                  )
                : Container(
                    color: AppTheme.backgroundColor,
                    padding: const EdgeInsets.all(18),
                    alignment: Alignment.center,
                    child: Text(
                      isWindowsDesktop
                          ? executablePath != null
                              ? 'Unity на Windows работает отдельным окном. Этот экран управляет JSON-синхронизацией, а само 3D-редактирование идет в Unity player.'
                              : 'Для desktop-режима нужен Unity Windows build. Положи .exe в map/Builds/Windows, и Flutter начнет запускать его автоматически.'
                          : 'Встраиваемая Unity-поверхность активируется на Android. На остальных платформах остается snapshot-режим.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
      ),
    );
  }
}
