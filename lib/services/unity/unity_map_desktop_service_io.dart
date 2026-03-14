import 'dart:convert';
import 'dart:io';

import '../../models/unity/unity_map_contract.dart';
import 'unity_map_desktop_service.dart';

UnityMapDesktopService createUnityMapDesktopService() => _IoUnityMapDesktopService();

class _IoUnityMapDesktopService implements UnityMapDesktopService {
  static const List<String> _preferredExecutableNames = [
    'ARTHOUSEMap.exe',
    'ARTHouseMap.exe',
    'ARTHOUSE.exe',
    'UnityMap.exe',
  ];

  Directory? _bridgeDirectory;
  String? _executablePath;

  @override
  bool get isSupported => Platform.isWindows;

  @override
  Future<UnityDesktopSessionInfo> inspect() async {
    if (!isSupported) {
      return const UnityDesktopSessionInfo(
        isAvailable: false,
        bridgeDirectory: '',
        message: 'Desktop Unity bridge доступен только на Windows.',
      );
    }

    final bridgeDirectory = await _ensureBridgeDirectory();
    final executablePath = await _resolveExecutablePath();
    return UnityDesktopSessionInfo(
      isAvailable: executablePath != null,
      bridgeDirectory: bridgeDirectory.path,
      executablePath: executablePath,
      message: executablePath == null
          ? 'Не найден Unity Windows player. Ожидается .exe в map/Builds/Windows.'
          : 'Unity Windows player найден и готов к запуску.',
    );
  }

  @override
  Future<UnityDesktopSessionInfo> startSession({
    required UnityApartmentMapData map,
    required String roomId,
  }) async {
    final sessionInfo = await inspect();
    if (!sessionInfo.isAvailable || sessionInfo.executablePath == null) {
      return sessionInfo;
    }

    await initializeEditor(map, roomId: roomId);
    await _launchExecutable(sessionInfo.executablePath!, sessionInfo.bridgeDirectory);

    return UnityDesktopSessionInfo(
      isAvailable: true,
      bridgeDirectory: sessionInfo.bridgeDirectory,
      executablePath: sessionInfo.executablePath,
      message: 'Unity desktop запущен через файловый bridge.',
    );
  }

  @override
  Future<void> initializeEditor(
    UnityApartmentMapData payload, {
    required String roomId,
  }) async {
    await _writeCommand(
      _DesktopCommandEnvelope(
        token: DateTime.now().microsecondsSinceEpoch.toString(),
        method: 'initializeEditor',
        payload: payload.toJsonString(),
        roomId: roomId,
      ),
    );
  }

  @override
  Future<void> focusRoom(String roomId) async {
    await _writeCommand(
      _DesktopCommandEnvelope(
        token: DateTime.now().microsecondsSinceEpoch.toString(),
        method: 'focusRoom',
        roomId: roomId,
      ),
    );
  }

  @override
  Future<void> undo() async {
    await _writeCommand(
      _DesktopCommandEnvelope(
        token: DateTime.now().microsecondsSinceEpoch.toString(),
        method: 'undo',
      ),
    );
  }

  @override
  Future<void> redo() async {
    await _writeCommand(
      _DesktopCommandEnvelope(
        token: DateTime.now().microsecondsSinceEpoch.toString(),
        method: 'redo',
      ),
    );
  }

  @override
  Future<String?> requestSnapshot() async {
    await _writeCommand(
      _DesktopCommandEnvelope(
        token: DateTime.now().microsecondsSinceEpoch.toString(),
        method: 'requestSnapshot',
      ),
    );

    for (var attempt = 0; attempt < 10; attempt++) {
      final snapshotJson = await _readSnapshotJson();
      if (snapshotJson != null && snapshotJson.isNotEmpty) {
        return snapshotJson;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    return null;
  }

  Future<Directory> _ensureBridgeDirectory() async {
    if (_bridgeDirectory != null) {
      return _bridgeDirectory!;
    }

    final workspaceDirectory = _findProjectDirectory();
    final bridgeDirectory = Directory(
      _join(workspaceDirectory.parent.path, '.unity_bridge', 'windows_session'),
    );
    await bridgeDirectory.create(recursive: true);
    _bridgeDirectory = bridgeDirectory;
    return bridgeDirectory;
  }

  Future<String?> _resolveExecutablePath() async {
    if (_executablePath != null && await File(_executablePath!).exists()) {
      return _executablePath;
    }

    final workspaceDirectory = _findProjectDirectory();
    final buildsDirectory = Directory(
      _join(workspaceDirectory.parent.path, 'map', 'Builds', 'Windows'),
    );

    for (final candidateName in _preferredExecutableNames) {
      final candidatePath = _join(buildsDirectory.path, candidateName);
      if (await File(candidatePath).exists()) {
        _executablePath = candidatePath;
        return candidatePath;
      }
    }

    if (await buildsDirectory.exists()) {
      final files = buildsDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.exe'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
      if (files.isNotEmpty) {
        _executablePath = files.first.path;
        return _executablePath;
      }
    }

    return null;
  }

  Future<void> _launchExecutable(String executablePath, String bridgeDirectory) async {
    await Process.start(
      executablePath,
      ['--arthouse-bridge-dir', bridgeDirectory],
      mode: ProcessStartMode.detached,
      runInShell: true,
      workingDirectory: File(executablePath).parent.path,
    );
  }

  Future<void> _writeCommand(_DesktopCommandEnvelope command) async {
    final bridgeDirectory = await _ensureBridgeDirectory();
    final commandFile = File(_join(bridgeDirectory.path, 'command.json'));
    await commandFile.writeAsString(
      jsonEncode(command.toJson()),
      flush: true,
    );
  }

  Future<String?> _readSnapshotJson() async {
    final bridgeDirectory = await _ensureBridgeDirectory();
    final snapshotFile = File(_join(bridgeDirectory.path, 'snapshot.json'));
    if (!await snapshotFile.exists()) {
      return null;
    }

    final rawContents = await snapshotFile.readAsString();
    if (rawContents.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawContents);
    if (decoded is Map<String, dynamic>) {
      final snapshotJson = decoded['snapshotJson'];
      if (snapshotJson is String && snapshotJson.isNotEmpty) {
        return snapshotJson;
      }
    }

    return rawContents;
  }

  Directory _findProjectDirectory() {
    Directory current = Directory.current;
    while (true) {
      if (File(_join(current.path, 'pubspec.yaml')).existsSync()) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError('Не удалось найти корень Flutter-проекта для Unity desktop bridge.');
      }
      current = parent;
    }
  }

  String _join(String first, String second, [String? third, String? fourth]) {
    final separator = Platform.pathSeparator;
    final parts = [first, second, if (third != null) third, if (fourth != null) fourth]
        .map((part) => part.replaceAll('/', separator).replaceAll('\\', separator))
        .toList();
    return parts.join(separator);
  }
}

class _DesktopCommandEnvelope {
  const _DesktopCommandEnvelope({
    required this.token,
    required this.method,
    this.payload,
    this.roomId,
  });

  final String token;
  final String method;
  final String? payload;
  final String? roomId;

  Map<String, Object?> toJson() {
    return {
      'token': token,
      'method': method,
      'payload': payload,
      'roomId': roomId,
    };
  }
}
