import '../../models/unity/unity_map_contract.dart';
import 'unity_map_desktop_service_stub.dart'
    if (dart.library.io) 'unity_map_desktop_service_io.dart';

final UnityMapDesktopService _unityMapDesktopService = createUnityMapDesktopService();

abstract class UnityMapDesktopService {
  static UnityMapDesktopService get instance => _unityMapDesktopService;

  bool get isSupported;

  Future<UnityDesktopSessionInfo> inspect();

  Future<UnityDesktopSessionInfo> startSession({
    required UnityApartmentMapData map,
    required String roomId,
  });

  Future<void> initializeEditor(
    UnityApartmentMapData payload, {
    required String roomId,
  });

  Future<void> focusRoom(String roomId);

  Future<void> undo();

  Future<void> redo();

  Future<String?> requestSnapshot();
}

class UnityDesktopSessionInfo {
  const UnityDesktopSessionInfo({
    required this.isAvailable,
    required this.bridgeDirectory,
    this.executablePath,
    this.message,
  });

  final bool isAvailable;
  final String bridgeDirectory;
  final String? executablePath;
  final String? message;
}
