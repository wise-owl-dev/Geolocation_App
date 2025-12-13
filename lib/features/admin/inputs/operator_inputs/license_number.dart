import 'package:formz/formz.dart';

// Define input validation errors para Número de Licencia
enum LicenseNumberError { empty, format }

// Clase para validación de Número de Licencia
class LicenseNumber extends FormzInput<String, LicenseNumberError> {
  // Cambiamos la expresión regular para solo aceptar números
  static final RegExp licenseNumberRegExp = RegExp(
    r'^[0-9]+$',
  );

  // Constructor para valor no modificado
  const LicenseNumber.pure() : super.pure('');

  // Constructor para valor modificado
  const LicenseNumber.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == LicenseNumberError.empty) return 'El número de licencia es requerido';
    // Actualizamos el mensaje de error para reflejar que solo se permiten números
    if (displayError == LicenseNumberError.format) return 'El número de licencia solo debe contener números';

    return null;
  }

  // Método de validación
  @override
  LicenseNumberError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LicenseNumberError.empty;
    if (!licenseNumberRegExp.hasMatch(value)) return LicenseNumberError.format;

    return null;
  }
}