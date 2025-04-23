import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user.dart' as CustomUser;

// Provider para el servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

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
        throw Exception('Autenticación fallida');
      }
      
      // Obtener datos completos del usuario
      final userData = await _supabase
          .from('usuarios')
          .select()
          .eq('id', response.user!.id)
          .single();
      
      return CustomUser.User.fromJson(userData);
    } catch (e) {
      print('Error en login: $e');
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }
  
  // Método para registro
  Future<CustomUser.User> signUp(String name, String lastName, String email, String password, String phone, {String? maternalLastName}) async {
    try {
      // Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Registro fallido');
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
      
      return CustomUser.User.fromJson(userData)!;
    } catch (e) {
      print('Error en registro: $e');
      throw Exception('Error al registrar usuario: ${e.toString()}');
    }
  }
  
  // Método para cerrar sesión
  Future<void> logout() async {
    await _supabase.auth.signOut();
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