import 'package:formz/formz.dart';

// Define input validation errors for Latitude (latitud)
enum LatitudeError { empty, format, invalid }

// Class for Latitude validation
class Latitude extends FormzInput<String, LatitudeError> {
  // Regex for latitude format (decimal number)
  static final RegExp latitudeRegExp = RegExp(
    r'^-?[0-9]+(\.[0-9]+)?$',
  );

  // Constructor for unmodified value
  const Latitude.pure() : super.pure('');

  // Constructor for modified value
  const Latitude.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == LatitudeError.empty) return 'La latitud es requerida';
    if (displayError == LatitudeError.format) return 'Formato de latitud inválido (ej. 19.4326)';
    if (displayError == LatitudeError.invalid) return 'La latitud debe estar entre -90 y 90';

    return null;
  }

  // Validation method
  @override
  LatitudeError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LatitudeError.empty;
    if (!latitudeRegExp.hasMatch(value)) return LatitudeError.format;
    
    final doubleValue = double.tryParse(value);
    if (doubleValue == null || doubleValue < -90 || doubleValue > 90) return LatitudeError.invalid;

    return null;
  }
}