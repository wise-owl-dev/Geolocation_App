import 'package:formz/formz.dart';

// Define input validation errors para Apellido
enum LastNameError { empty, format }

// Clase para validación de Apellido
class LastName extends FormzInput<String, LastNameError> {
  static final RegExp lastNameRegExp = RegExp(
    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
  );

  // Constructor para valor no modificado
  const LastName.pure() : super.pure('');

  // Constructor para valor modificado
  const LastName.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == LastNameError.empty) return 'El apellido es requerido';
    if (displayError == LastNameError.format) return 'El apellido solo debe contener letras';

    return null;
  }

  // Método de validación
  @override
  LastNameError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LastNameError.empty;
    if (!lastNameRegExp.hasMatch(value)) return LastNameError.format;

    return null;
  }
}