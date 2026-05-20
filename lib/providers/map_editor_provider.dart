import 'package:flutter/material.dart';

import '../models/unity/unity_map_contract.dart';

class MapEditorRoom {
  const MapEditorRoom({
    required this.name,
    required this.icon,
    required this.taskList,
  });

  final String name;
  final IconData icon;
  final List<String> taskList;

  int get tasksCount => taskList.length;

  MapEditorRoom copyWith({
    String? name,
    IconData? icon,
    List<String>? taskList,
  }) {
    return MapEditorRoom(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      taskList: taskList ?? this.taskList,
    );
  }
}

class MapEditorProvider extends ChangeNotifier {
  MapEditorProvider() : _rooms = _defaultRooms();

  List<MapEditorRoom> _rooms;
  DateTime? _lastSyncAt;
  String? _lastSnapshotJson;

  List<MapEditorRoom> get rooms => List.unmodifiable(_rooms);
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastSnapshotJson => _lastSnapshotJson;

  String get syncStatusLabel {
    if (_lastSyncAt == null) {
      return 'Unity еще не синхронизировал изменения обратно во фронт';
    }

    final hour = _lastSyncAt!.hour.toString().padLeft(2, '0');
    final minute = _lastSyncAt!.minute.toString().padLeft(2, '0');
    return 'Последняя синхронизация с Unity: $hour:$minute';
  }

  void deleteRoom(String name) {
    _rooms = _rooms.where((room) => room.name != name).toList();
    notifyListeners();
  }

  /// Полностью заменить список комнат (например, при открытии карты конкретного
  /// проекта). Иконки подбираем по имени.
  void replaceRooms(Iterable<String> names) {
    final cleaned = <String>{};
    for (final raw in names) {
      final n = raw.trim();
      if (n.isNotEmpty) cleaned.add(n);
    }
    if (cleaned.isEmpty) return;
    _rooms = cleaned
        .map(
          (n) => MapEditorRoom(
            name: n,
            icon: iconForRoomName(n),
            taskList: const [],
          ),
        )
        .toList();
    notifyListeners();
  }

  void addRoom(String name, IconData icon) {
    if (_rooms.any((room) => room.name == name)) {
      return;
    }

    _rooms = [
      ..._rooms,
      MapEditorRoom(name: name, icon: icon, taskList: const []),
    ];
    notifyListeners();
  }

  String roomIdFromName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('ё', 'e')
        .replaceAll('й', 'i')
        .replaceAll('ь', '')
        .replaceAll('ъ', '')
        .replaceAll('а', 'a')
        .replaceAll('б', 'b')
        .replaceAll('в', 'v')
        .replaceAll('г', 'g')
        .replaceAll('д', 'd')
        .replaceAll('е', 'e')
        .replaceAll('ж', 'zh')
        .replaceAll('з', 'z')
        .replaceAll('и', 'i')
        .replaceAll('к', 'k')
        .replaceAll('л', 'l')
        .replaceAll('м', 'm')
        .replaceAll('н', 'n')
        .replaceAll('о', 'o')
        .replaceAll('п', 'p')
        .replaceAll('р', 'r')
        .replaceAll('с', 's')
        .replaceAll('т', 't')
        .replaceAll('у', 'u')
        .replaceAll('ф', 'f')
        .replaceAll('х', 'h')
        .replaceAll('ц', 'c')
        .replaceAll('ч', 'ch')
        .replaceAll('ш', 'sh')
        .replaceAll('щ', 'sch')
        .replaceAll('ы', 'y')
        .replaceAll('э', 'e')
        .replaceAll('ю', 'yu')
        .replaceAll('я', 'ya');
  }

  UnityGridCoord roomGridForName(String name) {
    switch (name) {
      case 'Ванная':
        return const UnityGridCoord(x: 4, y: 4);
      case 'Спальня':
      case 'Кухня':
      case 'Детская':
        return const UnityGridCoord(x: 6, y: 5);
      case 'Кабинет':
        return const UnityGridCoord(x: 5, y: 4);
      default:
        return const UnityGridCoord(x: 8, y: 6);
    }
  }

  UnityApartmentMapData buildUnityPayload() {
    final roomsPayload = _rooms.map((room) {
      return UnityRoomData(
        roomId: roomIdFromName(room.name),
        displayName: room.name,
        gridSize: roomGridForName(room.name),
        floorMaterialId: 'floor_oak',
        wallMaterialId: 'wall_warm_white',
        walls: const [],
        openings: const [],
        stairs: const [],
        furniture: const [],
      );
    }).toList();

    final tasksPayload = <UnityTaskMarker>[];
    for (final room in _rooms) {
      final roomId = roomIdFromName(room.name);
      for (var index = 0; index < room.taskList.length; index++) {
        tasksPayload.add(
          UnityTaskMarker(
            taskId: '${roomId}_task_$index',
            roomId: roomId,
            furnitureInstanceId: '',
            title: room.taskList[index],
            description: '',
            status: UnityTaskStatus.todo,
          ),
        );
      }
    }

    return UnityApartmentMapData(
      apartmentId: 'arthouse_demo_apartment',
      apartmentName: 'ARTHouse Demo Apartment',
      rooms: roomsPayload,
      tasks: tasksPayload,
    );
  }

  void applyUnitySnapshot(UnityApartmentMapData map, {String? rawJson}) {
    final groupedTasks = <String, List<String>>{};
    for (final task in map.tasks) {
      groupedTasks.putIfAbsent(task.roomId, () => <String>[]).add(task.title);
    }

    _rooms = map.rooms.map((room) {
      final roomTasks = groupedTasks[room.roomId] ?? const <String>[];
      return MapEditorRoom(
        name: room.displayName,
        icon: iconForRoomName(room.displayName),
        taskList: List<String>.from(roomTasks),
      );
    }).toList();

    _lastSyncAt = DateTime.now();
    _lastSnapshotJson = rawJson ?? map.toJsonString();
    notifyListeners();
  }

  static IconData iconForRoomName(String roomName) {
    switch (roomName) {
      case 'Гостиная':
        return Icons.weekend;
      case 'Спальня':
        return Icons.bed;
      case 'Кухня':
        return Icons.kitchen;
      case 'Ванная':
        return Icons.bathtub;
      case 'Кабинет':
        return Icons.computer;
      case 'Детская':
        return Icons.child_care;
      case 'Прихожая':
        return Icons.door_front_door;
      case 'Балкон':
        return Icons.balcony;
      case 'Гардероб':
        return Icons.checkroom;
      case 'Столовая':
        return Icons.dining;
      case 'Терраса':
        return Icons.deck;
      case 'Коридор':
        return Icons.sensor_door;
      case 'Кладовая':
        return Icons.inventory_2;
      case 'Лоджия':
        return Icons.window;
      case 'Гостевая':
        return Icons.hotel;
      case 'Игровая':
        return Icons.sports_esports;
      default:
        return Icons.home_work_rounded;
    }
  }

  static List<MapEditorRoom> _defaultRooms() {
    return const [
      MapEditorRoom(name: 'Гостиная', icon: Icons.weekend, taskList: ['Пропылесосить', 'Протереть пыль']),
      MapEditorRoom(name: 'Спальня', icon: Icons.bed, taskList: []),
      MapEditorRoom(name: 'Кухня', icon: Icons.kitchen, taskList: ['Помыть посуду']),
      MapEditorRoom(name: 'Ванная', icon: Icons.bathtub, taskList: ['Помыть унитаз', 'Протереть раковину', 'Вымыть кафель']),
      MapEditorRoom(name: 'Кабинет', icon: Icons.computer, taskList: []),
      MapEditorRoom(name: 'Детская', icon: Icons.child_care, taskList: ['Убрать игрушки']),
    ];
  }
}