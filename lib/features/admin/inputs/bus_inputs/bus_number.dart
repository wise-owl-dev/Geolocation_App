import 'package:formz/formz.dart';

// Define input validation errors for Bus Number (numero_unidad)
enum BusNumberError { empty, format }

// Class for Bus Number validation
class BusNumber extends FormzInput<String, BusNumberError> {
  // Constructor for unmodified value
  const BusNumber.pure() : super.pure('');

  // Constructor for modified value
  const BusNumber.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == BusNumberError.empty) return 'El número de unidad es requerido';
    if (displayError == BusNumberError.format) return 'El número de unidad no es válido';

    return null;
  }

  // Validation method
  @override
  BusNumberError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return BusNumberError.empty;
    // We're just checking if it's not empty for now, but we could add more specific validation
    
    return null;
  }
}