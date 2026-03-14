class ApartmentSceneFurniture {
  const ApartmentSceneFurniture({
    required this.id,
    required this.roomIndex,
    required this.name,
    required this.width,
    required this.depth,
    required this.height,
    required this.normX,
    required this.normZ,
    required this.color,
    this.modelUrl,
    this.rotationY = 0,
  });

  final String id;
  final int roomIndex;
  final String name;
  final double width;
  final double depth;
  final double height;
  final double normX;
  final double normZ;
  final int color;
  final String? modelUrl;
  final double rotationY;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'roomIndex': roomIndex,
      'name': name,
      'width': width,
      'depth': depth,
      'height': height,
      'normX': normX,
      'normZ': normZ,
      'color': color,
      'modelUrl': modelUrl,
      'rotationY': rotationY,
    };
  }
}

class ApartmentSceneRoom {
  const ApartmentSceneRoom({
    required this.index,
    required this.name,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    required this.selected,
    required this.furniture,
  });

  final int index;
  final String name;
  final double left;
  final double top;
  final double width;
  final double height;
  final int color;
  final bool selected;
  final List<ApartmentSceneFurniture> furniture;

  Map<String, Object?> toJson() {
    return {
      'index': index,
      'name': name,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'color': color,
      'selected': selected,
      'furniture': furniture.map((item) => item.toJson()).toList(),
    };
  }
}

class ApartmentScenePayload {
  const ApartmentScenePayload({
    required this.gridWidth,
    required this.gridHeight,
    required this.activeRoomIndex,
    required this.rooms,
  });

  final double gridWidth;
  final double gridHeight;
  final int activeRoomIndex;
  final List<ApartmentSceneRoom> rooms;

  Map<String, Object?> toJson() {
    return {
      'gridWidth': gridWidth,
      'gridHeight': gridHeight,
      'activeRoomIndex': activeRoomIndex,
      'rooms': rooms.map((room) => room.toJson()).toList(),
    };
  }
}
