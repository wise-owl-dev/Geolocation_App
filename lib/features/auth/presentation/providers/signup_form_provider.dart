// lib/features/auth/presentation/providers/signup_form_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'auth_provider.dart';
import '../../../shared/infrastructure/inputs/email.dart';
import '../../../shared/infrastructure/inputs/password.dart';
import '../../../shared/infrastructure/inputs/name.dart';
import '../../../shared/infrastructure/inputs/last_name.dart';
import '../../../shared/infrastructure/inputs/phone.dart';

// Estado del formulario de registro
class SignUpFormState {
  final Name name;
  final LastName lastName;
  final LastName maternalLastName;
  final Email email;
  final Password password;
  final Password confirmPassword;
  final Phone phone;
  final bool isValid;
  final bool isPosting;
  final bool isFormPosted;
  final bool passwordsMatch;

  SignUpFormState({
    this.name = const Name.pure(),
    this.lastName = const LastName.pure(),
    this.maternalLastName = const LastName.pure(),
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.confirmPassword = const Password.pure(),
    this.phone = const Phone.pure(),
    this.isValid = false,
    this.isPosting = false,
    this.isFormPosted = false,
    this.passwordsMatch = true,
  });

  SignUpFormState copyWith({
    Name? name,
    LastName? lastName,
    LastName? maternalLastName,
    Email? email,
    Password? password,
    Password? confirmPassword,
    Phone? phone,
    bool? isValid,
    bool? isPosting,
    bool? isFormPosted,
    bool? passwordsMatch,
  }) {
    return SignUpFormState(
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      maternalLastName: maternalLastName ?? this.maternalLastName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      phone: phone ?? this.phone,
      isValid: isValid ?? this.isValid,
      isPosting: isPosting ?? this.isPosting,
      isFormPosted: isFormPosted ?? this.isFormPosted,
      passwordsMatch: passwordsMatch ?? this.passwordsMatch,
    );
  }

  @override
  String toString() {
    return '''
      SignUpFormState:
        name: $name
        lastName: $lastName
        maternalLastName: $maternalLastName
        email: $email
        password: $password
        confirmPassword: $confirmPassword
        phone: $phone
        isValid: $isValid
        isPosting: $isPosting
        isFormPosted: $isFormPosted
        passwordsMatch: $passwordsMatch
    ''';
  }
}

// Notificador para gestionar el estado del formulario
class SignUpFormNotifier extends StateNotifier<SignUpFormState> {
  final AuthNotifier authNotifier;
  
  SignUpFormNotifier({
    required this.authNotifier,
  }) : super(SignUpFormState());

  void onNameChanged(String value) {
    final name = Name.dirty(value);
    _validateForm(name: name);
  }

  void onLastNameChanged(String value) {
    final lastName = LastName.dirty(value);
    _validateForm(lastName: lastName);
  }

  void onMaternalLastNameChanged(String value) {
    final maternalLastName = LastName.dirty(value);
    _validateForm(maternalLastName: maternalLastName);
  }

  void onEmailChange(String value) {
    final email = Email.dirty(value);
    _validateForm(email: email);
  }

  void onPasswordChanged(String value) {
    final password = Password.dirty(value);
    final passwordsMatch = password.value == state.confirmPassword.value;
    _validateForm(password: password, passwordsMatch: passwordsMatch);
  }

  void onConfirmPasswordChanged(String value) {
    final confirmPassword = Password.dirty(value);
    final passwordsMatch = state.password.value == confirmPassword.value;
    _validateForm(confirmPassword: confirmPassword, passwordsMatch: passwordsMatch);
  }

  void onPhoneChanged(String value) {
    final phone = Phone.dirty(value);
    _validateForm(phone: phone);
  }

  // Método para validar el formulario completo
  void _validateForm({
    Name? name,
    LastName? lastName,
    LastName? maternalLastName,
    Email? email,
    Password? password,
    Password? confirmPassword,
    Phone? phone,
    bool? passwordsMatch,
  }) {
    final newName = name ?? state.name;
    final newLastName = lastName ?? state.lastName;
    final newMaternalLastName = maternalLastName ?? state.maternalLastName;
    final newEmail = email ?? state.email;
    final newPassword = password ?? state.password;
    final newConfirmPassword = confirmPassword ?? state.confirmPassword;
    final newPhone = phone ?? state.phone;
    final newPasswordsMatch = passwordsMatch ?? state.passwordsMatch;

    final isValid = Formz.validate([
      newName,
      newLastName,
      newEmail,
      newPassword,
      newConfirmPassword,
      newPhone,
    ]) && newPasswordsMatch;

    state = state.copyWith(
      name: newName,
      lastName: newLastName,
      maternalLastName: newMaternalLastName,
      email: newEmail,
      password: newPassword,
      confirmPassword: newConfirmPassword,
      phone: newPhone,
      isValid: isValid,
      passwordsMatch: newPasswordsMatch,
    );
  }

  // Método para "tocar" todos los campos y mostrar errores
  void _touchEveryField() {
    final name = Name.dirty(state.name.value);
    final lastName = LastName.dirty(state.lastName.value);
    final maternalLastName = LastName.dirty(state.maternalLastName.value);
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final confirmPassword = Password.dirty(state.confirmPassword.value);
    final phone = Phone.dirty(state.phone.value);
    final passwordsMatch = password.value == confirmPassword.value;

    state = state.copyWith(
      name: name,
      lastName: lastName,
      maternalLastName: maternalLastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
      isValid: Formz.validate([name, lastName, email, password, confirmPassword, phone]) && passwordsMatch,
      isFormPosted: true,
      passwordsMatch: passwordsMatch,
    );
  }

  // Método para enviar el formulario
  Future<void> onFormSubmit() async {
    _touchEveryField();
    
    if (!state.isValid) return;
    
    state = state.copyWith(isPosting: true);
    
    try {
      // Registrar al usuario
      await authNotifier.signUp(
        name: state.name.value,
        lastName: state.lastName.value,
        maternalLastName: state.maternalLastName.value,
        email: state.email.value,
        password: state.password.value,
        phone: state.phone.value,
      );
      
      state = state.copyWith(isPosting: false);
    } catch (e) {
      state = state.copyWith(isPosting: false);
      throw e;
    }
  }
}

// Provider para acceder al estado y notificador del formulario
final signUpFormProvider = StateNotifierProvider<SignUpFormNotifier, SignUpFormState>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  
  return SignUpFormNotifier(
    authNotifier: authNotifier,
  );
});