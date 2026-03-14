import 'dart:convert';

enum UnityLayoutToolType { floor, wall, door, arch, stair }

enum UnityFurnitureCategory {
  kitchen,
  bedroom,
  livingRoom,
  bathroom,
  kidsRoom,
  office,
  storage,
  decor,
  appliance,
}

enum UnityTaskStatus { todo, inProgress, done }

class UnityGridCoord {
  const UnityGridCoord({required this.x, required this.y});

  final int x;
  final int y;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };

  factory UnityGridCoord.fromJson(Map<String, dynamic> json) => UnityGridCoord(
        x: (json['x'] as num?)?.toInt() ?? 0,
        y: (json['y'] as num?)?.toInt() ?? 0,
      );
}

class UnityWallSegment {
  const UnityWallSegment({
    required this.wallId,
    required this.start,
    required this.end,
    required this.materialId,
  });

  final String wallId;
  final UnityGridCoord start;
  final UnityGridCoord end;
  final String materialId;

  Map<String, dynamic> toJson() => {
        'wallId': wallId,
        'start': start.toJson(),
        'end': end.toJson(),
        'materialId': materialId,
      };

  factory UnityWallSegment.fromJson(Map<String, dynamic> json) => UnityWallSegment(
        wallId: json['wallId'] as String? ?? '',
        start: UnityGridCoord.fromJson((json['start'] as Map?)?.cast<String, dynamic>() ?? const {}),
        end: UnityGridCoord.fromJson((json['end'] as Map?)?.cast<String, dynamic>() ?? const {}),
        materialId: json['materialId'] as String? ?? 'wall_warm_white',
      );
}

class UnityOpening {
  const UnityOpening({
    required this.openingId,
    required this.type,
    required this.wallId,
    required this.offset,
    required this.width,
    required this.height,
  });

  final String openingId;
  final UnityLayoutToolType type;
  final String wallId;
  final double offset;
  final double width;
  final double height;

  Map<String, dynamic> toJson() => {
        'openingId': openingId,
        'type': type.name,
        'wallId': wallId,
        'offset': offset,
        'width': width,
        'height': height,
      };

  factory UnityOpening.fromJson(Map<String, dynamic> json) => UnityOpening(
        openingId: json['openingId'] as String? ?? '',
        type: UnityLayoutToolType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => UnityLayoutToolType.door,
        ),
        wallId: json['wallId'] as String? ?? '',
        offset: (json['offset'] as num?)?.toDouble() ?? 0.5,
        width: (json['width'] as num?)?.toDouble() ?? 1,
        height: (json['height'] as num?)?.toDouble() ?? 2.1,
      );
}

class UnityStairData {
  const UnityStairData({
    required this.stairId,
    required this.gridPosition,
    required this.footprint,
    required this.rotationQuarterTurns,
    required this.materialId,
  });

  final String stairId;
  final UnityGridCoord gridPosition;
  final UnityGridCoord footprint;
  final int rotationQuarterTurns;
  final String materialId;

  Map<String, dynamic> toJson() => {
        'stairId': stairId,
        'gridPosition': gridPosition.toJson(),
        'footprint': footprint.toJson(),
        'rotationQuarterTurns': rotationQuarterTurns,
        'materialId': materialId,
      };

  factory UnityStairData.fromJson(Map<String, dynamic> json) => UnityStairData(
        stairId: json['stairId'] as String? ?? '',
        gridPosition: UnityGridCoord.fromJson((json['gridPosition'] as Map?)?.cast<String, dynamic>() ?? const {}),
        footprint: UnityGridCoord.fromJson((json['footprint'] as Map?)?.cast<String, dynamic>() ?? const {}),
        rotationQuarterTurns: (json['rotationQuarterTurns'] as num?)?.toInt() ?? 0,
        materialId: json['materialId'] as String? ?? 'stair_oak',
      );
}

class UnityFurnitureItem {
  const UnityFurnitureItem({
    required this.instanceId,
    required this.roomId,
    required this.templateId,
    required this.displayName,
    required this.category,
    required this.gridPosition,
    required this.footprint,
    required this.rotationQuarterTurns,
    required this.supportsStackingAbove,
    required this.requiresSupportSurface,
    required this.blocksPlacement,
    required this.parentFurnitureInstanceId,
    required this.elevation,
  });

  final String instanceId;
  final String roomId;
  final String templateId;
  final String displayName;
  final UnityFurnitureCategory category;
  final UnityGridCoord gridPosition;
  final UnityGridCoord footprint;
  final int rotationQuarterTurns;
  final bool supportsStackingAbove;
  final bool requiresSupportSurface;
  final bool blocksPlacement;
  final String parentFurnitureInstanceId;
  final double elevation;

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'roomId': roomId,
        'templateId': templateId,
        'displayName': displayName,
        'category': category.name,
        'gridPosition': gridPosition.toJson(),
        'footprint': footprint.toJson(),
        'rotationQuarterTurns': rotationQuarterTurns,
        'supportsStackingAbove': supportsStackingAbove,
        'requiresSupportSurface': requiresSupportSurface,
        'blocksPlacement': blocksPlacement,
        'parentFurnitureInstanceId': parentFurnitureInstanceId,
        'elevation': elevation,
      };

  factory UnityFurnitureItem.fromJson(Map<String, dynamic> json) => UnityFurnitureItem(
        instanceId: json['instanceId'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        templateId: json['templateId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        category: UnityFurnitureCategory.values.firstWhere(
          (value) => value.name == json['category'],
          orElse: () => UnityFurnitureCategory.decor,
        ),
        gridPosition: UnityGridCoord.fromJson((json['gridPosition'] as Map?)?.cast<String, dynamic>() ?? const {}),
        footprint: UnityGridCoord.fromJson((json['footprint'] as Map?)?.cast<String, dynamic>() ?? const {}),
        rotationQuarterTurns: (json['rotationQuarterTurns'] as num?)?.toInt() ?? 0,
        supportsStackingAbove: json['supportsStackingAbove'] as bool? ?? false,
        requiresSupportSurface: json['requiresSupportSurface'] as bool? ?? false,
        blocksPlacement: json['blocksPlacement'] as bool? ?? true,
        parentFurnitureInstanceId: json['parentFurnitureInstanceId'] as String? ?? '',
        elevation: (json['elevation'] as num?)?.toDouble() ?? 0,
      );
}

class UnityTaskMarker {
  const UnityTaskMarker({
    required this.taskId,
    required this.roomId,
    required this.furnitureInstanceId,
    required this.title,
    required this.description,
    required this.status,
  });

  final String taskId;
  final String roomId;
  final String furnitureInstanceId;
  final String title;
  final String description;
  final UnityTaskStatus status;

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'roomId': roomId,
        'furnitureInstanceId': furnitureInstanceId,
        'title': title,
        'description': description,
        'status': status.name,
      };

  factory UnityTaskMarker.fromJson(Map<String, dynamic> json) => UnityTaskMarker(
        taskId: json['taskId'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        furnitureInstanceId: json['furnitureInstanceId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: UnityTaskStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => UnityTaskStatus.todo,
        ),
      );
}

class UnityRoomData {
  const UnityRoomData({
    required this.roomId,
    required this.displayName,
    required this.gridSize,
    required this.floorMaterialId,
    required this.wallMaterialId,
    required this.walls,
    required this.openings,
    required this.stairs,
    required this.furniture,
  });

  final String roomId;
  final String displayName;
  final UnityGridCoord gridSize;
  final String floorMaterialId;
  final String wallMaterialId;
  final List<UnityWallSegment> walls;
  final List<UnityOpening> openings;
  final List<UnityStairData> stairs;
  final List<UnityFurnitureItem> furniture;

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'displayName': displayName,
        'gridSize': gridSize.toJson(),
        'floorMaterialId': floorMaterialId,
        'wallMaterialId': wallMaterialId,
        'walls': walls.map((item) => item.toJson()).toList(),
        'openings': openings.map((item) => item.toJson()).toList(),
        'stairs': stairs.map((item) => item.toJson()).toList(),
        'furniture': furniture.map((item) => item.toJson()).toList(),
      };

  factory UnityRoomData.fromJson(Map<String, dynamic> json) => UnityRoomData(
        roomId: json['roomId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        gridSize: UnityGridCoord.fromJson((json['gridSize'] as Map?)?.cast<String, dynamic>() ?? const {}),
        floorMaterialId: json['floorMaterialId'] as String? ?? 'floor_oak',
        wallMaterialId: json['wallMaterialId'] as String? ?? 'wall_warm_white',
        walls: ((json['walls'] as List?) ?? const [])
            .map((item) => UnityWallSegment.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
        openings: ((json['openings'] as List?) ?? const [])
            .map((item) => UnityOpening.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
        stairs: ((json['stairs'] as List?) ?? const [])
          .map((item) => UnityStairData.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
        furniture: ((json['furniture'] as List?) ?? const [])
            .map((item) => UnityFurnitureItem.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class UnityApartmentMapData {
  const UnityApartmentMapData({
    required this.apartmentId,
    required this.apartmentName,
    required this.rooms,
    required this.tasks,
  });

  final String apartmentId;
  final String apartmentName;
  final List<UnityRoomData> rooms;
  final List<UnityTaskMarker> tasks;

  Map<String, dynamic> toJson() => {
        'apartmentId': apartmentId,
        'apartmentName': apartmentName,
        'rooms': rooms.map((item) => item.toJson()).toList(),
        'tasks': tasks.map((item) => item.toJson()).toList(),
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory UnityApartmentMapData.fromJson(Map<String, dynamic> json) => UnityApartmentMapData(
        apartmentId: json['apartmentId'] as String? ?? 'apartment_default',
        apartmentName: json['apartmentName'] as String? ?? 'ARTHouse Apartment',
        rooms: ((json['rooms'] as List?) ?? const [])
            .map((item) => UnityRoomData.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
        tasks: ((json['tasks'] as List?) ?? const [])
            .map((item) => UnityTaskMarker.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
      );

  factory UnityApartmentMapData.fromJsonString(String jsonString) =>
      UnityApartmentMapData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}