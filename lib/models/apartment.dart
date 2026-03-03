/// Модель квартиры
class Apartment {
  final int id;
  final int userId;
  final String name;
  final double? ceilingHeight;
  final double? squareMeters;
  final int? floors;
  final int? roomsCount;
  final String? address;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Apartment({
    required this.id,
    required this.userId,
    required this.name,
    this.ceilingHeight,
    this.squareMeters,
    this.floors,
    this.roomsCount,
    this.address,
    required this.createdAt,
    this.updatedAt,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      ceilingHeight: json['ceiling_height'] != null 
          ? (json['ceiling_height'] as num).toDouble() 
          : null,
      squareMeters: json['square_meters'] != null 
          ? (json['square_meters'] as num).toDouble() 
          : null,
      floors: json['floors'] as int?,
      roomsCount: json['rooms_count'] as int?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'ceiling_height': ceilingHeight,
      'square_meters': squareMeters,
      'floors': floors,
      'rooms_count': roomsCount,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Apartment copyWith({
    int? id,
    int? userId,
    String? name,
    double? ceilingHeight,
    double? squareMeters,
    int? floors,
    int? roomsCount,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Apartment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      squareMeters: squareMeters ?? this.squareMeters,
      floors: floors ?? this.floors,
      roomsCount: roomsCount ?? this.roomsCount,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Модель для создания квартиры
class ApartmentCreate {
  final String name;
  final double? ceilingHeight;
  final double? squareMeters;
  final int? floors;
  final int? roomsCount;
  final String? address;

  ApartmentCreate({
    required this.name,
    this.ceilingHeight,
    this.squareMeters,
    this.floors,
    this.roomsCount,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (ceilingHeight != null) json['ceiling_height'] = ceilingHeight;
    if (squareMeters != null) json['square_meters'] = squareMeters;
    if (floors != null) json['floors'] = floors;
    if (roomsCount != null) json['rooms_count'] = roomsCount;
    if (address != null) json['address'] = address;
    return json;
  }
}

/// Модель для обновления квартиры
class ApartmentUpdate {
  final String? name;
  final double? ceilingHeight;
  final double? squareMeters;
  final int? floors;
  final int? roomsCount;
  final String? address;

  ApartmentUpdate({
    this.name,
    this.ceilingHeight,
    this.squareMeters,
    this.floors,
    this.roomsCount,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (ceilingHeight != null) json['ceiling_height'] = ceilingHeight;
    if (squareMeters != null) json['square_meters'] = squareMeters;
    if (floors != null) json['floors'] = floors;
    if (roomsCount != null) json['rooms_count'] = roomsCount;
    if (address != null) json['address'] = address;
    return json;
  }
}
