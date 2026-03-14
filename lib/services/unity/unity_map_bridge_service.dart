import 'package:flutter/services.dart';

import '../../models/unity/unity_map_contract.dart';

class UnityMapBridgeService {
  UnityMapBridgeService._();

  static final UnityMapBridgeService instance = UnityMapBridgeService._();

  static const String platformViewType = 'arthouse/unity_map_view';
  static const MethodChannel _channel = MethodChannel('arthouse/unity_map_bridge');

  Future<bool> isUnityAvailable() async {
    final available = await _safeInvoke<bool>('isAvailable');
    return available ?? false;
  }

  Future<void> initializeEditor(UnityApartmentMapData payload) async {
    await _safeInvoke<void>('initializeEditor', payload.toJsonString());
  }

  Future<void> focusRoom(String roomId) async {
    await _safeInvoke<void>('focusRoom', roomId);
  }

  Future<void> undo() async {
    await _safeInvoke<void>('undo');
  }

  Future<void> redo() async {
    await _safeInvoke<void>('redo');
  }

  Future<String?> requestSnapshot() async {
    return _safeInvoke<String>('requestSnapshot');
  }

  Future<T?> _safeInvoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}