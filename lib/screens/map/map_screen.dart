import 'package:flutter/material.dart';
import 'editor/apartment_editor_screen.dart';

/// Экран «Карта» — единый общий 3D-вид квартиры.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ApartmentEditorScreen();
  }
}