import 'package:formz/formz.dart';

// Define input validation errors for License Plate (placa)
enum LicensePlateError { empty, format }

// Class for License Plate validation
class LicensePlate extends FormzInput<String, LicensePlateError> {
  // Regex for license plate format (this is just an example, adjust as needed)
  static final RegExp licensePlateRegExp = RegExp(
    r'^[A-Z0-9-]+$',
  );

  // Constructor for unmodified value
  const LicensePlate.pure() : super.pure('');

  // Constructor for modified value
  const LicensePlate.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == LicensePlateError.empty) return 'La placa es requerida';
    if (displayError == LicensePlateError.format) return 'Formato de placa no válido';

    return null;
  }

  // Validation method
  @override
  LicensePlateError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return LicensePlateError.empty;
    if (!licensePlateRegExp.hasMatch(value)) return LicensePlateError.format;

    return null;
  }
}