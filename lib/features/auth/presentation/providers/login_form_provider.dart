// lib/features/auth/presentation/providers/login_form_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'auth_provider.dart';
import '../../../shared/infrastructure/inputs/email.dart';
import '../../../shared/infrastructure/inputs/password.dart';

// Estado del formulario de login
class LoginFormState {
  final Email email;
  final Password password;
  final bool isValid;
  final bool isPosting;
  final bool isFormPosted;

  LoginFormState({
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.isValid = false,
    this.isPosting = false,
    this.isFormPosted = false,
  });

  LoginFormState copyWith({
    Email? email,
    Password? password,
    bool? isValid,
    bool? isPosting,
    bool? isFormPosted,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      isPosting: isPosting ?? this.isPosting,
      isFormPosted: isFormPosted ?? this.isFormPosted,
    );
  }

  // Método de conveniencia para depuración
  @override
  String toString() {
    return '''
      LoginFormState:
        email: $email
        password: $password
        isValid: $isValid
        isPosting: $isPosting
        isFormPosted: $isFormPosted
    ''';
  }
}

// Notificador para gestionar el estado del formulario
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  final AuthNotifier authNotifier;
  
  LoginFormNotifier({
    required this.authNotifier,
  }) : super(LoginFormState());

  // Método para validar el email
  void onEmailChange(String value) {
    final email = Email.dirty(value);
    
    state = state.copyWith(
      email: email,
      isValid: Formz.validate([email, state.password]),
    );
  }

  // Método para validar la contraseña
  void onPasswordChanged(String value) {
    final password = Password.dirty(value);
    
    state = state.copyWith(
      password: password,
      isValid: Formz.validate([state.email, password]),
    );
  }

  // Método para "tocar" todos los campos y mostrar errores
  void _touchEveryField() {
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);

    state = state.copyWith(
      email: email,
      password: password,
      isValid: Formz.validate([email, password]),
      isFormPosted: true,
    );
  }

  // Método para enviar el formulario
  Future<void> onFormSubmit() async {
    // Marcar como enviado para mostrar mensajes de error si los hay
    _touchEveryField();
    
    // Si no es válido, retornar
    if (!state.isValid) return;
    
    // Actualizar estado a enviando
    state = state.copyWith(isPosting: true);
    
    try {
      // Llamar al método de login del provider de autenticación
      await authNotifier.login(state.email.value, state.password.value);
      
      // Actualizar estado final
      state = state.copyWith(isPosting: false);
    } catch (e) {
      // Manejar error y actualizar estado
      state = state.copyWith(isPosting: false);
      throw e; // Re-lanzar para manejo en UI
    }
  }
}

// Provider para acceder al estado y notificador del formulario
final loginFormProvider = StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  
  return LoginFormNotifier(
    authNotifier: authNotifier,
  );
});