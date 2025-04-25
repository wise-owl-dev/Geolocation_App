import 'package:formz/formz.dart';

// Define input validation errors para Tipo de Licencia
enum LicenseTypeError { empty }

// Clase para validación de Tipo de Licencia
class LicenseType extends FormzInput<String, LicenseTypeError> {
  // Constructor para valor no modificado
  const LicenseType.pure() : super.pure('');

  // Constructor para valor modificado
  const LicenseType.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == LicenseTypeError.empty) return 'El tipo de licencia es requerido';

    return null;
  }

  // Método de validación
  @override
  LicenseTypeError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LicenseTypeError.empty;

    return null;
  }
}