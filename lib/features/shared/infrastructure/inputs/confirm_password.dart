// lib/features/shared/infrastructure/inputs/confirm_password.dart
import 'package:formz/formz.dart';

// Define input validation errors para confirmación de contraseña
enum ConfirmPasswordError { empty, length, format, mismatch }

// Clase para validación de confirmación de contraseña
class ConfirmPassword extends FormzInput<String, ConfirmPasswordError> {
  final String originalPassword;

  static final RegExp passwordRegExp = RegExp(
    r'(?:(?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$',
  );

  // Constructor para valor no modificado
  const ConfirmPassword.pure({this.originalPassword = ''}) : super.pure('');

  // Constructor para valor modificado
  const ConfirmPassword.dirty({required this.originalPassword, required String value}) 
      : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == ConfirmPasswordError.empty) return 'El campo es requerido';
    if (displayError == ConfirmPasswordError.length) return 'Mínimo 6 caracteres';
    if (displayError == ConfirmPasswordError.format) return 'Debe de tener Mayúscula, letras y un número';
    if (displayError == ConfirmPasswordError.mismatch) return 'Las contraseñas no coinciden';

    return null;
  }

  // Método de validación
  @override
  ConfirmPasswordError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return ConfirmPasswordError.empty;
    if (value.length < 6) return ConfirmPasswordError.length;
    if (!passwordRegExp.hasMatch(value)) return ConfirmPasswordError.format;
    if (value != originalPassword) return ConfirmPasswordError.mismatch;

    return null;
  }
}