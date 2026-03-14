import 'package:flutter/material.dart';

import '../../../models/unity/unity_map_contract.dart';

class UnityMapWebController {
  Future<bool> isUnityAvailable() async => false;

  Future<void> initializeEditor(UnityApartmentMapData payload) async {}

  Future<void> focusRoom(String roomId) async {}

  Future<void> undo() async {}

  Future<void> redo() async {}

  Future<String?> requestSnapshot() async => null;

  String? get lastStatusMessage => null;
}

class UnityMapWebSurface extends StatelessWidget {
  const UnityMapWebSurface({super.key, required this.controller});

  final UnityMapWebController controller;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
