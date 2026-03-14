/// Роли пользователей
enum UserRole {
  user,
  admin,
}

/// Типы пользователей
enum UserType {
  b2c,
  b2b,
  service,
}

/// Модель пользователя
class User {
  final int id;
  final String email;
  final String username;
  final UserRole role;
  final UserType userType;
  final bool isActive;
  final bool isVerified;
  final bool surveyCompleted;
  final int? roomsCount;
  final int? floorsCount;
  final int? wallHeight;
  final int? totalArea;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.role = UserRole.user,
    this.userType = UserType.b2c,
    required this.isActive,
    this.isVerified = false,
    this.surveyCompleted = false,
    this.roomsCount,
    this.floorsCount,
    this.wallHeight,
    this.totalArea,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      // backend returns full_name; username is a frontend-only alias
      username: (json['full_name'] as String?)  ??
                (json['username'] as String?)    ??
                '',
      role: _parseRole(json['role'] as String?),
      userType: _parseUserType(json['user_type'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      surveyCompleted: json['survey_completed'] as bool? ?? false,
      roomsCount: json['rooms_count'] as int?,
      floorsCount: json['floors_count'] as int?,
      wallHeight: json['wall_height'] as int?,
      totalArea: json['total_area'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  static UserType _parseUserType(String? value) {
    switch (value) {
      case 'b2b':
        return UserType.b2b;
      case 'service':
        return UserType.service;
      default:
        return UserType.b2c;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role.name,
      'user_type': userType.name,
      'is_active': isActive,
      'is_verified': isVerified,
      'survey_completed': surveyCompleted,
      'rooms_count': roomsCount,
      'floors_count': floorsCount,
      'wall_height': wallHeight,
      'total_area': totalArea,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? username,
    UserRole? role,
    UserType? userType,
    bool? isActive,
    bool? isVerified,
    bool? surveyCompleted,
    int? roomsCount,
    int? floorsCount,
    int? wallHeight,
    int? totalArea,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
      roomsCount: roomsCount ?? this.roomsCount,
      floorsCount: floorsCount ?? this.floorsCount,
      wallHeight: wallHeight ?? this.wallHeight,
      totalArea: totalArea ?? this.totalArea,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Модель для регистрации пользователя
class UserCreate {
  final String email;
  final String username;
  final String password;
  final UserType userType;

  UserCreate({
    required this.email,
    required this.username,
    required this.password,
    this.userType = UserType.b2c,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'full_name': username,   // backend field name
      'password': password,
      'user_type': userType.name,
    };
  }
}

/// Модель для входа
class UserLogin {
  final String email;
  final String password;

  UserLogin({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Модель токена авторизации
class AuthToken {
  final String accessToken;
  final String tokenType;

  AuthToken({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }
}
