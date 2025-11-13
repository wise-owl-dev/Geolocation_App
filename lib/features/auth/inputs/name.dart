import 'package:formz/formz.dart';

// Define input validation errors para Nombre
enum NameError { empty, format }

// Clase para validación de Nombre
class Name extends FormzInput<String, NameError> {
  static final RegExp nameRegExp = RegExp(
    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
  );

  // Constructor para valor no modificado
  const Name.pure() : super.pure('');

  // Constructor para valor modificado
  const Name.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == NameError.empty) return 'El nombre es requerido';
    if (displayError == NameError.format) return 'El nombre solo debe contener letras';

    return null;
  }

  // Método de validación
  @override
  NameError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return NameError.empty;
    if (!nameRegExp.hasMatch(value)) return NameError.format;

    return null;
  }
}