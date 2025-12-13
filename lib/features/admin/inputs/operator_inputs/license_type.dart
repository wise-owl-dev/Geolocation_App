import 'package:formz/formz.dart';

// Define input validation errors para Tipo de Licencia
enum LicenseTypeError { empty, format }

// Clase para validación de Tipo de Licencia
class LicenseType extends FormzInput<String, LicenseTypeError> {
  // Agregamos una expresión regular para validar solo letras y espacios
  static final RegExp licenseTypeRegExp = RegExp(
    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
  );

  // Constructor para valor no modificado
  const LicenseType.pure() : super.pure('');

  // Constructor para valor modificado
  const LicenseType.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == LicenseTypeError.empty) return 'El tipo de licencia es requerido';
    // Agregamos mensaje de error para formato inválido
    if (displayError == LicenseTypeError.format) return 'El tipo de licencia solo debe contener letras';

    return null;
  }

  // Método de validación modificado para incluir validación de formato
  @override
  LicenseTypeError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LicenseTypeError.empty;
    // Validamos que solo contenga letras y espacios
    if (!licenseTypeRegExp.hasMatch(value)) return LicenseTypeError.format;

    return null;
  }
}