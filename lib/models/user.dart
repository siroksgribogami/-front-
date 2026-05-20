import '../utils/user_contact_display.dart';

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
  /// Отображаемое имя (поле `display_name` на бэкенде).
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
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
    this.displayName,
    this.phone,
    this.avatarUrl,
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

  /// Имя для UI: display_name, иначе username.
  String get visibleName {
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    return username.trim();
  }

  /// Первая буква для аватара-заглушки (без RangeError на пустой строке).
  String get avatarInitial {
    final name = visibleName;
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  bool get hasSyntheticPhoneEmail =>
      UserContactDisplay.isSyntheticPhoneEmail(email);

  /// Реальный email для UI (служебный @phone.arthouse.app скрыт).
  String? get displayEmail => hasSyntheticPhoneEmail ? null : email.trim();

  /// Телефон для UI.
  String? get displayPhone {
    final fromField = phone?.trim();
    if (fromField != null && fromField.isNotEmpty) {
      return UserContactDisplay.formatPhoneRu(fromField);
    }
    return UserContactDisplay.phoneFromSyntheticEmail(email);
  }

  /// Подпись под именем: телефон или email.
  String? get contactSubtitle {
    final p = displayPhone;
    if (p != null && p.isNotEmpty) return p;
    return displayEmail;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    final id = idVal is int
        ? idVal
        : idVal is num
            ? idVal.toInt()
            : int.tryParse('$idVal') ?? 0;

    final createdRaw = json['created_at'];
    DateTime createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return User(
      id: id,
      email: json['email'] as String? ?? '',
      // art_back UserResponse: username; старые ветки: full_name
      username: (json['username'] as String?) ??
          (json['full_name'] as String?) ??
          '',
      displayName: json['display_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: _parseRole(json['role']),
      userType: _parseUserType(json['user_type'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      surveyCompleted: json['survey_completed'] as bool? ?? false,
      roomsCount: (json['rooms_count'] as num?)?.toInt(),
      floorsCount: (json['floors_count'] as num?)?.toInt(),
      wallHeight: (json['wall_height'] as num?)?.toInt(),
      totalArea: (json['total_area'] as num?)?.toInt(),
      createdAt: createdAt,
    );
  }

  static UserRole _parseRole(dynamic value) {
    switch (value?.toString()) {
      case 'admin':
        return UserRole.admin;
      case 'customer':
      case 'master':
        return UserRole.user;
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
      'display_name': displayName,
      'phone': phone,
      'avatar_url': avatarUrl,
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
    String? displayName,
    String? phone,
    String? avatarUrl,
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
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
  final String? phone;
  final String? role;

  UserCreate({
    required this.email,
    required this.username,
    required this.password,
    this.userType = UserType.b2c,
    this.phone,
    this.role,
  });

  /// Тело для `ARThouse-backend` `POST /api/v1/register`.
  /// Добавляем `phone` и `role` опционально для серверной схемы.
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'email': email,
      'username': username,
      'password': password,
    };
    if (phone != null) m['phone'] = phone;
    if (role != null) m['role'] = role;
    return m;
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
