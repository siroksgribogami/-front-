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
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.role = UserRole.user,
    this.userType = UserType.b2c,
    required this.isActive,
    this.isVerified = false,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      role: _parseRole(json['role'] as String?),
      userType: _parseUserType(json['user_type'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Модель для регистрации пользователя
class UserCreate {
  final String email;
  final String username;
  final String password;

  UserCreate({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
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
