import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart' as CustomAuth;
import '../../../../core/services/auth_service.dart' as CustomAuthService;
import '../../../../core/services/auth_service.dart' as CustomAuthException show AuthException;
import '../../../../shared/models/user.dart' as CustomUser;

class AddOperatorState {
  final bool isLoading;
  final User? user;
  final bool isSuccess;
  final String? error;
  final String? errorCode;

  AddOperatorState({
    required this.isLoading,
    this.user,
    required this.isSuccess,
    this.error,
    this.errorCode,
  });

  // Estado inicial
  factory AddOperatorState.initial() => AddOperatorState(
    isLoading: false,
    user: null,
    isSuccess: false,
    error: null,
    errorCode: null,
  );

  // Método copyWith para inmutabilidad
  AddOperatorState copyWith({
    bool? isLoading,
    User? user,
    bool? isSuccess,
    String? error,
    String? errorCode,
  }) {
    return AddOperatorState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      errorCode: errorCode,
    );
  }
}

class AddOperatorNotifier extends StateNotifier<AddOperatorState> {
  final CustomAuth.AuthService _authService;
  final _supabase = Supabase.instance.client;

  AddOperatorNotifier(this._authService) : super(AddOperatorState.initial());

  Future<void> createOperator({
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
    state = state.copyWith(isLoading: true, error: null, errorCode: null, isSuccess: false);
    
    try {
      // PRIMERO: Verificar si el email ya existe
      final emailExists = await _authService.emailExists(email);
      if (emailExists) {
        throw CustomAuth.AuthException(
          message: 'Este email ya está registrado. Intenta con otro.',
          code: 'auth/email-already-exists'
        );
      }
      
      // Verificar si el número de licencia ya existe
      final licenseExists = await _checkLicenseExists(licenseNumber);
      if (licenseExists) {
        throw CustomAuthService.AuthException(
          message: 'Este número de licencia ya está registrado.',
          code: 'auth/license-already-exists'
        );
      }
      
      // SEGUNDO: Crear el usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw CustomAuthException.AuthException(
          message: 'No se pudo completar el registro. Intenta de nuevo.',
          code: 'auth/signup-failed'
        );
      }
      
      final userId = response.user!.id;
      
      // TERCERO: Insertar datos en la tabla 'usuarios' con rol operador
      await _supabase.from('usuarios').insert({
        'id': userId,
        'email': email,
        'nombre': name,
        'apellido_paterno': lastName,
        'apellido_materno': maternalLastName,
        'telefono': phone,
        'rol': 'operador', // Importante: usar rol operador, no usuario
      });
      
      // CUARTO: Insertar datos en la tabla 'operadores'
      final hireDateStr = hireDate.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
      
      await _supabase.from('operadores').insert({
        'id': userId,
        'numero_licencia': licenseNumber,
        'tipo_licencia': licenseType,
        'experiencia_anios': yearsExperience,
        'fecha_contratacion': hireDateStr,
      });
      
      /// QUINTO: Obtener el usuario creado
    final userData = await _supabase
        .from('usuarios')
        .select()
        .eq('id', userId)
        .single();

    final createdUser = User.fromJson(userData);

    state = state.copyWith(
      isLoading: false, 
      user: createdUser,  // Ahora no hay ambigüedad
      isSuccess: true,
    );
      
    } catch (e) {
      String errorMessage;
      String errorCode = 'auth/unknown';
      
      if (e is AuthException) {
        errorMessage = e.message;
        errorCode = e.code ?? 'unknown-error';
      } else {
        errorMessage = e.toString();
      }
      
      state = state.copyWith(
        isLoading: false, 
        error: errorMessage,
        errorCode: errorCode,
        isSuccess: false,
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

  void clearError() {
    state = state.copyWith(error: null, errorCode: null);
  }
  
  void reset() {
    state = AddOperatorState.initial();
  }
}

final addOperatorProvider = StateNotifierProvider<AddOperatorNotifier, AddOperatorState>((ref) {
  final authService = ref.read(CustomAuth.authServiceProvider);
  return AddOperatorNotifier(authService);
});