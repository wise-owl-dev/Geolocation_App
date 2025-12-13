import 'package:formz/formz.dart';

// Define input validation errors for Capacity (capacidad)
enum CapacityError { empty, format, invalid }

// Class for Capacity validation
class Capacity extends FormzInput<String, CapacityError> {
  static final RegExp capacityRegExp = RegExp(
    r'^[0-9]+$',
  );

  // Constructor for unmodified value
  const Capacity.pure() : super.pure('');

  // Constructor for modified value
  const Capacity.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == CapacityError.empty) return 'La capacidad es requerida';
    if (displayError == CapacityError.format) return 'Ingrese solo números';
    if (displayError == CapacityError.invalid) return 'La capacidad debe ser mayor a 0';

    return null;
  }

  // Validation method
  @override
  CapacityError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return CapacityError.empty;
    if (!capacityRegExp.hasMatch(value)) return CapacityError.format;
    
    final intValue = int.tryParse(value);
    if (intValue == null || intValue <= 0) return CapacityError.invalid;

    return null;
  }
}