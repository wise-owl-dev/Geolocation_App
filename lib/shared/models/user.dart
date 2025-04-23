// Enumeración para los roles de usuario
enum UserRole {
  admin,
  operator,
  user,
}

// Modelo de usuario
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? profileImage;
  final String? lastNamePaterno;
  final String? lastNameMaterno;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImage,
    this.lastNamePaterno,
    this.lastNameMaterno,
  });

  // Métodos para verificar roles
  bool get isAdmin => role == UserRole.admin;
  bool get isOperator => role == UserRole.operator;
  bool get isRegularUser => role == UserRole.user;

  // Factory constructor desde JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['nombre'] as String,
      email: json['email'] as String,
      role: _roleFromString(json['rol'] as String),
      phone: json['telefono'] as String?,
      profileImage: json['profile_image'] as String?,
      lastNamePaterno: json['apellido_paterno'] as String?,
      lastNameMaterno: json['apellido_materno'] as String?,
    );
  }

  // Método toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'rol': _roleToString(role),
      'telefono': phone,
      'profile_image': profileImage,
      'apellido_paterno': lastNamePaterno,
      'apellido_materno': lastNameMaterno,
    };
  }

  // Métodos auxiliares para convertir entre String y UserRole
  static UserRole _roleFromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'operador':
        return UserRole.operator;
      default:
        return UserRole.user;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.operator:
        return 'operador';
      case UserRole.user:
        return 'usuario';
    }
  }

  // Método copyWith para crear una copia con cambios
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? profileImage,
    String? lastNamePaterno,
    String? lastNameMaterno,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      lastNamePaterno: lastNamePaterno ?? this.lastNamePaterno,
      lastNameMaterno: lastNameMaterno ?? this.lastNameMaterno,
    );
  }
}