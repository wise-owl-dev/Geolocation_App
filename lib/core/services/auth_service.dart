import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user.dart' as CustomUser;

// Provider para el servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Clase para manejar errores específicos de autenticación
class AuthException implements Exception {
  final String message;
  final String code;

  AuthException({required this.message, required this.code});

  @override
  String toString() => message;
}

// Inicializar Supabase
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://ggesrgpdcoshvfbkoiwg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnZXNyZ3BkY29zaHZmYmtvaXdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0NDMyNTIsImV4cCI6MjA2MTAxOTI1Mn0.ei0smgnGWx1uW-PEjuyWyULTeiZVIE3tgGEnjLMuqjM',
  );
}

// Servicio de autenticación con Supabase
class AuthService {
  final _supabase = Supabase.instance.client;
  
  // Método para obtener el usuario actual (si hay sesión)
  Future<CustomUser.User?> getCurrentUser() async {
    try {
      // Verificar si hay sesión activa
      final session = _supabase.auth.currentSession;
      if (session == null) return null;
      
      // Obtener datos del usuario desde la tabla 'usuarios'
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id', session.user.id)
          .single();
      
      return CustomUser.User.fromJson(response);
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  // Método para iniciar sesión
  Future<CustomUser.User> login(String email, String password) async {
    try {
      // Autenticar usando Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException(
          message: 'No se pudo iniciar sesión. Verifica tus credenciales.',
          code: 'auth/invalid-credentials'
        );
      }
      
      // Obtener datos completos del usuario
      final userData = await _supabase
          .from('usuarios')
          .select()
          .eq('id', response.user!.id)
          .single();
      
      return CustomUser.User.fromJson(userData);
    } on AuthException {
      rethrow;
    } catch (e) {
      // Manejar diferentes tipos de errores de Supabase
      if (e is AuthException) rethrow;
      
      if (e.toString().contains('Invalid login credentials')) {
        throw AuthException(
          message: 'Email o contraseña incorrectos. Intenta de nuevo.',
          code: 'auth/invalid-credentials'
        );
      }
      
      if (e.toString().contains('Email not confirmed')) {
        throw AuthException(
          message: 'Por favor, confirma tu email antes de iniciar sesión.',
          code: 'auth/email-not-verified'
        );
      }
      
      if (e.toString().contains('Rate limit')) {
        throw AuthException(
          message: 'Demasiados intentos fallidos. Intenta más tarde.',
          code: 'auth/too-many-requests'
        );
      }
      
      print('Error en login: $e');
      throw AuthException(
        message: 'Error al iniciar sesión. Intenta de nuevo más tarde.',
        code: 'auth/unknown'
      );
    }
  }
  
  // Método para registro
  Future<CustomUser.User> signUp(String name, String lastName, String email, String password, String phone, {String? maternalLastName}) async {
    try {
      // Verificar si el email ya existe
      final emailExists = await this.emailExists(email);
      if (emailExists) {
        throw AuthException(
          message: 'Este email ya está registrado. Intenta con otro o inicia sesión.',
          code: 'auth/email-already-exists'
        );
      }
      
      // Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException(
          message: 'No se pudo completar el registro. Intenta de nuevo.',
          code: 'auth/signup-failed'
        );
      }
      
      // Insertar datos adicionales en la tabla 'usuarios'
      await _supabase.from('usuarios').insert({
        'id': response.user!.id,
        'email': email,
        'nombre': name,
        'apellido_paterno': lastName,
        'apellido_materno': maternalLastName,
        'telefono': phone,
        'rol': 'usuario', // Por defecto es usuario normal
      });
      
      // Obtener el usuario recién creado
      final userData = await _supabase
          .from('usuarios')
          .select()
          .eq('id', response.user!.id)
          .single();
      
      return CustomUser.User.fromJson(userData);
    } on AuthException {
      rethrow;
    } catch (e) {
      // Manejar diferentes tipos de errores de Supabase
      if (e is AuthException) rethrow;
      
      if (e.toString().contains('already registered')) {
        throw AuthException(
          message: 'Este email ya está registrado. Intenta con otro o inicia sesión.',
          code: 'auth/email-already-exists'
        );
      }
      
      if (e.toString().contains('password')) {
        throw AuthException(
          message: 'La contraseña no cumple con los requisitos de seguridad.',
          code: 'auth/weak-password'
        );
      }
      
      print('Error en registro: $e');
      throw AuthException(
        message: 'Error al registrar usuario. Intenta de nuevo más tarde.',
        code: 'auth/unknown'
      );
    }
  }
  
  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error en logout: $e');
      throw AuthException(
        message: 'Error al cerrar sesión. Intenta de nuevo.',
        code: 'auth/signout-failed'
      );
    }
  }

  // Método para verificar si ya existe un email
  Future<bool> emailExists(String email) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('email')
          .eq('email', email);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error verificando email: $e');
      return false;
    }
  }
// Método mejorado para crear un operador
Future<User> createOperator({
  required String name,
  required String lastName,
  required String email,
  required String password,
  required String phone,
  required String licenseNumber,
  required String licenseType,
  required int yearsExperience,
  required DateTime hireDate,
  String? maternalLastName,
}) async {
  try {
    // Verificar si el email ya existe
    final emailExists = await this.emailExists(email);
    if (emailExists) {
      throw AuthException(
        message: 'Este email ya está registrado. Intenta con otro.',
        code: 'auth/email-already-exists'
      );
    }
    
    // Verificar si el número de licencia ya existe
    final licenseExists = await _checkLicenseExists(licenseNumber);
    if (licenseExists) {
      throw AuthException(
        message: 'Este número de licencia ya está registrado.',
        code: 'auth/license-already-exists'
      );
    }
    
    // Crear usuario en Supabase Auth
    print('Creando usuario en Supabase Auth...');
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw AuthException(
        message: 'No se pudo completar el registro. Intenta de nuevo.',
        code: 'auth/signup-failed'
      );
    }
    
    final userId = response.user!.id;
    print('Usuario creado con ID: $userId');
    
    // Insertar datos en la tabla 'usuarios'
    print('Insertando datos en la tabla usuarios...');
    try {
      await _supabase.from('usuarios').insert({
        'id': userId,
        'email': email,
        'nombre': name,
        'apellido_paterno': lastName,
        'apellido_materno': maternalLastName,
        'telefono': phone,
        'rol': 'operador', // Asignar rol de operador
      });
      print('Datos insertados correctamente en la tabla usuarios');
    } catch (e) {
      print('Error insertando en tabla usuarios: $e');
      // Si falla la inserción en usuarios, eliminar el usuario de Auth
      await _supabase.auth.admin.deleteUser(userId);
      throw AuthException(
        message: 'Error al registrar usuario en la base de datos: $e',
        code: 'auth/db-error'
      );
    }
    
    // Insertar datos específicos del operador
    print('Insertando datos en la tabla operadores...');
    try {
      // Convertir la fecha a formato ISO y tomar solo la parte de la fecha
      final hireDateStr = hireDate.toIso8601String().split('T')[0];
      print('Fecha de contratación formateada: $hireDateStr');
      
      await _supabase.from('operadores').insert({
        'id': userId,
        'numero_licencia': licenseNumber,
        'tipo_licencia': licenseType,
        'experiencia_anios': yearsExperience,
        'fecha_contratacion': hireDateStr,
      });
      print('Datos insertados correctamente en la tabla operadores');
    } catch (e) {
      print('Error insertando en tabla operadores: $e');
      // Si falla la inserción en operadores, podríamos eliminar el usuario
      // o dejar que el administrador lo complete manualmente
      throw AuthException(
        message: 'Error al registrar datos del operador: $e',
        code: 'auth/db-error-operator'
      );
    }
    
    // Obtener el usuario creado
    print('Obteniendo datos completos del usuario creado...');
    final userData = await _supabase
        .from('usuarios')
        .select()
        .eq('id', userId)
        .single();
    
    return User.fromJson(userData)!;
  } on AuthException {
    rethrow;
  } catch (e) {
    print('Error inesperado en createOperator: $e');
    throw AuthException(
      message: 'Error al registrar operador: $e',
      code: 'auth/unknown'
    );
  }
}

// Método auxiliar para verificar si ya existe un número de licencia
Future<bool> _checkLicenseExists(String licenseNumber) async {
  try {
    final response = await _supabase
        .from('operadores')
        .select('numero_licencia')
        .eq('numero_licencia', licenseNumber);
    
    return response.isNotEmpty;
  } catch (e) {
    print('Error verificando licencia: $e');
    return false;
  }
}
}