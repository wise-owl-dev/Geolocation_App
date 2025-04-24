import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user.dart';

// Estado de autenticación
class AuthState {
  final bool isLoading;
  final User? user;
  final bool isAuthenticated;
  final String? error;
  final String? errorCode;

  AuthState({
    required this.isLoading,
    this.user,
    required this.isAuthenticated,
    this.error,
    this.errorCode,
  });

  // Estado inicial
  factory AuthState.initial() => AuthState(
    isLoading: false,
    user: null,
    isAuthenticated: false,
    error: null,
    errorCode: null,
  );

  // Método copyWith para inmutabilidad
  AuthState copyWith({
    bool? isLoading,
    User? user,
    bool? isAuthenticated,
    String? error,
    String? errorCode,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      errorCode: errorCode,
    );
  }
}

// Notificador para manejar el estado de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    // Verificar si hay usuario actualmente autenticado
    _checkCurrentUser();
  }

  // Método para verificar si hay un usuario autenticado
  Future<void> _checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final user = await _authService.getCurrentUser();
      
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: user != null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al verificar la sesión: ${e.toString()}',
      );
    }
  }

  // Método de login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    
    try {
      final user = await _authService.login(email, password);
      
      state = state.copyWith(
        isLoading: false, 
        user: user, 
        isAuthenticated: true,
      );
    } catch (e) {
      String errorMessage;
      String errorCode = 'auth/unknown';
      
      if (e is AuthException) {
        errorMessage = e.message;
        errorCode = e.code;
      } else {
        errorMessage = e.toString();
      }
      
      state = state.copyWith(
        isLoading: false, 
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  // Método de registro
  Future<void> signUp(String name, String lastName, String maternalLastName, String email, String password, String phone) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    
    try {
      final user = await _authService.signUp(
        name, 
        lastName, 
        email, 
        password, 
        phone,
        maternalLastName: maternalLastName.isNotEmpty ? maternalLastName : null
      );
      
      state = state.copyWith(
        isLoading: false, 
        user: user, 
        isAuthenticated: true,
      );
    } catch (e) {
      String errorMessage;
      String errorCode = 'auth/unknown';
      
      if (e is AuthException) {
        errorMessage = e.message;
        errorCode = e.code;
      } else {
        errorMessage = e.toString();
      }
      
      state = state.copyWith(
        isLoading: false, 
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  // Método de logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.logout();
      state = AuthState.initial();
    } catch (e) {
      String errorMessage;
      String errorCode = 'auth/unknown';
      
      if (e is AuthException) {
        errorMessage = e.message;
        errorCode = e.code;
      } else {
        errorMessage = e.toString();
      }
      
      state = state.copyWith(
        isLoading: false, 
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  // Método para limpiar errores
  void clearError() {
    state = state.copyWith(error: null, errorCode: null);
  }
}

// Provider para el estado de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});