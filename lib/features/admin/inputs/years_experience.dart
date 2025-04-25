import 'package:formz/formz.dart';

// Define input validation errors para Años de Experiencia
enum YearsExperienceError { empty, format, invalid }

// Clase para validación de Años de Experiencia
class YearsExperience extends FormzInput<String, YearsExperienceError> {
  static final RegExp yearsRegExp = RegExp(
    r'^[0-9]+$',
  );

  // Constructor para valor no modificado
  const YearsExperience.pure() : super.pure('');

  // Constructor para valor modificado
  const YearsExperience.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == YearsExperienceError.empty) return 'Los años de experiencia son requeridos';
    if (displayError == YearsExperienceError.format) return 'Ingrese solo números';
    if (displayError == YearsExperienceError.invalid) return 'El valor debe estar entre 0 y 50';

    return null;
  }

  // Método de validación
  @override
  YearsExperienceError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return YearsExperienceError.empty;
    if (!yearsRegExp.hasMatch(value)) return YearsExperienceError.format;
    
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 50) return YearsExperienceError.invalid;

    return null;
  }
}