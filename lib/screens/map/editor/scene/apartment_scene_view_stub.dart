import 'package:flutter/material.dart';

import 'apartment_scene_models.dart';

class ApartmentSceneView extends StatelessWidget {
  const ApartmentSceneView({
    super.key,
    required this.payload,
    required this.onRoomTap,
  });

  final ApartmentScenePayload payload;
  final ValueChanged<int> onRoomTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16120F),
      alignment: Alignment.center,
      child: const Text(
        '3D scene is available in Chrome/web build only',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
