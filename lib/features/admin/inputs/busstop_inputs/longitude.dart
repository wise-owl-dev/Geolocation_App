import 'package:formz/formz.dart';

// Define input validation errors for Longitude (longitud)
enum LongitudeError { empty, format, invalid }

// Class for Longitude validation
class Longitude extends FormzInput<String, LongitudeError> {
  // Regex for longitude format (decimal number)
  static final RegExp longitudeRegExp = RegExp(
    r'^-?[0-9]+(\.[0-9]+)?$',
  );

  // Constructor for unmodified value
  const Longitude.pure() : super.pure('');

  // Constructor for modified value
  const Longitude.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == LongitudeError.empty) return 'La longitud es requerida';
    if (displayError == LongitudeError.format) return 'Formato de longitud inválido (ej. -99.1332)';
    if (displayError == LongitudeError.invalid) return 'La longitud debe estar entre -180 y 180';

    return null;
  }

  // Validation method
  @override
  LongitudeError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LongitudeError.empty;
    if (!longitudeRegExp.hasMatch(value)) return LongitudeError.format;
    
    final doubleValue = double.tryParse(value);
    if (doubleValue == null || doubleValue < -180 || doubleValue > 180) return LongitudeError.invalid;

    return null;
  }
}