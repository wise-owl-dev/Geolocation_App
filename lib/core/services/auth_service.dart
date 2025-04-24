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
}