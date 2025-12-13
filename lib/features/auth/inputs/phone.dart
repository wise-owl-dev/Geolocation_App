import 'package:formz/formz.dart';

// Define input validation errors para Teléfono
enum PhoneError { empty, format, length }

// Clase para validación de Teléfono
class Phone extends FormzInput<String, PhoneError> {
  static final RegExp phoneRegExp = RegExp(
    r'^[0-9]+$',
  );

  // Constructor para valor no modificado
  const Phone.pure() : super.pure('');

  // Constructor para valor modificado
  const Phone.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == PhoneError.empty) return 'El teléfono es requerido';
    if (displayError == PhoneError.format) return 'El teléfono solo debe contener números';
    if (displayError == PhoneError.length) return 'El teléfono debe tener entre 8 y 15 dígitos';

    return null;
  }

  // Método de validación
  @override
  PhoneError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return PhoneError.empty;
    if (!phoneRegExp.hasMatch(value)) return PhoneError.format;
    if (value.length < 8 || value.length > 15) return PhoneError.length;

    return null;
  }
}