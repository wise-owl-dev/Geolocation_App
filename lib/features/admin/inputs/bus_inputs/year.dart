import 'package:formz/formz.dart';

// Define input validation errors for Year (año)
enum YearError { empty, format, invalid }

// Class for Year validation
class Year extends FormzInput<String, YearError> {
  static final RegExp yearRegExp = RegExp(
    r'^[0-9]+$',
  );

  // Constructor for unmodified value
  const Year.pure() : super.pure('');

  // Constructor for modified value
  const Year.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == YearError.empty) return 'El año es requerido';
    if (displayError == YearError.format) return 'Ingrese solo números';
    if (displayError == YearError.invalid) return 'El año debe estar entre 1950 y el año actual';

    return null;
  }

  // Validation method
  @override
  YearError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return YearError.empty;
    if (!yearRegExp.hasMatch(value)) return YearError.format;
    
    final intValue = int.tryParse(value);
    final currentYear = DateTime.now().year;
    if (intValue == null || intValue < 1950 || intValue > currentYear) {
      return YearError.invalid;
    }

    return null;
  }
}