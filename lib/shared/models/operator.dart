import '../../../shared/models/user.dart';

class Operator {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? lastNamePaterno;
  final String? lastNameMaterno;
  final String licenseNumber;
  final String licenseType;
  final int yearsExperience;
  final DateTime hireDate;

  Operator({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.lastNamePaterno,
    this.lastNameMaterno,
    required this.licenseNumber,
    required this.licenseType,
    required this.yearsExperience,
    required this.hireDate,
  });

  // Factory constructor desde JSON
  factory Operator.fromJson(Map<String, dynamic> json) {
    print('Creando Operator desde JSON: $json');
    
    // Convertir string de rol a UserRole enum
    UserRole roleFromString(String roleStr) {
      switch (roleStr.toLowerCase()) {
        case 'admin':
          return UserRole.admin;
        case 'operador':
          return UserRole.operator;
        default:
          return UserRole.user;
      }
    }
    
    // Manejar posibles tipos diferentes para experiencia_anios
    int parseYearsExperience(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    // Manejar posibles formatos de fecha
    DateTime parseHireDate(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parseando fecha: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    try {
      return Operator(
        id: json['id'] as String,
        name: json['nombre'] as String,
        email: json['email'] as String,
        role: roleFromString(json['rol'] as String),
        phone: json['telefono'] as String?,
        lastNamePaterno: json['apellido_paterno'] as String?,
        lastNameMaterno: json['apellido_materno'] as String?,
        licenseNumber: json['numero_licencia'] as String,
        licenseType: json['tipo_licencia'] as String,
        yearsExperience: parseYearsExperience(json['experiencia_anios']),
        hireDate: parseHireDate(json['fecha_contratacion']),
      );
    } catch (e) {
      print('Error al crear Operator desde JSON: $e');
      rethrow;
    }
  }

  // Método toJson
  Map<String, dynamic> toJson() {
    // Convertir UserRole enum a string
    String roleToString(UserRole role) {
      switch (role) {
        case UserRole.admin:
          return 'admin';
        case UserRole.operator:
          return 'operador';
        case UserRole.user:
          return 'usuario';
      }
    }
    
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'rol': roleToString(role),
      'telefono': phone,
      'apellido_paterno': lastNamePaterno,
      'apellido_materno': lastNameMaterno,
      'numero_licencia': licenseNumber,
      'tipo_licencia': licenseType,
      'experiencia_anios': yearsExperience,
      'fecha_contratacion': hireDate.toIso8601String().split('T')[0],
    };
  }

  // Obtener nombre completo
  String get fullName {
    String fullName = name;
    
    if (lastNamePaterno != null && lastNamePaterno!.isNotEmpty) {
      fullName += ' $lastNamePaterno';
    }
    
    if (lastNameMaterno != null && lastNameMaterno!.isNotEmpty) {
      fullName += ' $lastNameMaterno';
    }
    
    return fullName;
  }
}