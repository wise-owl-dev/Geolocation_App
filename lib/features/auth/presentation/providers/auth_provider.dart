// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Estado para manejar la autenticación
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? userRole;
  final String? error;
  final String? email;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userRole,
    this.error,
    this.email,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? userRole,
    String? error,
    String? email,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      error: error ?? this.error,
      email: email ?? this.email,
    );
  }
}

// Notificador para gestionar el estado de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  // Método para iniciar sesión
  Future<void> login(String email, String password) async {
    // Actualizar estado a cargando
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulación de login para pruebas
      await Future.delayed(const Duration(seconds: 2));
      
      // Simular rol basado en el email (solo para pruebas)
      String role = 'usuario';
      if (email.contains('admin')) {
        role = 'administrador';
      } else if (email.contains('operador')) {
        role = 'operador';
      }
      
      // Actualizar estado a autenticado con el rol
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userRole: role,
        email: email,
      );
    } catch (e) {
      // Manejar error
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );
      throw e; // Re-lanzar para manejo en UI
    }
  }

  // Método para registrar un nuevo usuario
  Future<void> signUp({
    required String name,
    required String lastName,
    String? maternalLastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulación de registro para pruebas
      await Future.delayed(const Duration(seconds: 2));
      
      // En una implementación real, aquí llamarías a tu API o servicio de autenticación
      // Por ahora, simulamos un registro exitoso
      
      // Actualizar estado (en un caso real, podrías autenticar inmediatamente o requerir login)
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true, // Autenticar inmediatamente después del registro
        userRole: 'usuario', // Por defecto, los nuevos usuarios son estándar
        email: email,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulación de cierre de sesión
      await Future.delayed(const Duration(seconds: 1));
      
      // Resetear estado
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  // Método para verificar el estado de autenticación actual
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Aquí implementarías la lógica para verificar si hay una sesión activa
      // Por ahora, simulamos que no hay sesión
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Provider para acceder al estado de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});