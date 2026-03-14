import '../../models/unity/unity_map_contract.dart';
import 'unity_map_desktop_service.dart';

UnityMapDesktopService createUnityMapDesktopService() => _UnsupportedUnityMapDesktopService();

class _UnsupportedUnityMapDesktopService implements UnityMapDesktopService {
  @override
  bool get isSupported => false;

  @override
  Future<UnityDesktopSessionInfo> inspect() async {
    return const UnityDesktopSessionInfo(
      isAvailable: false,
      bridgeDirectory: '',
      message: 'Desktop Unity bridge доступен только на Windows.',
    );
  }

  @override
  Future<UnityDesktopSessionInfo> startSession({
    required UnityApartmentMapData map,
    required String roomId,
  }) {
    return inspect();
  }

  @override
  Future<void> initializeEditor(
    UnityApartmentMapData payload, {
    required String roomId,
  }) async {}

  @override
  Future<void> focusRoom(String roomId) async {}

  @override
  Future<void> undo() async {}

  @override
  Future<void> redo() async {}

  @override
  Future<String?> requestSnapshot() async => null;
}
