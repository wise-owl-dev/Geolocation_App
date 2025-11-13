import 'package:formz/formz.dart';

// Define input validation errors for Reference (referencia)
enum ReferenceError { tooLong } // Añadimos un valor al enum

// Class for Reference validation (optional field)
class Reference extends FormzInput<String, ReferenceError> {
  // Constructor for unmodified value
  const Reference.pure() : super.pure('');

  // Constructor for modified value
  const Reference.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;
    
    if (displayError == ReferenceError.tooLong) return 'La referencia es demasiado larga';

    return null;
  }

  // Validation method
  @override
  ReferenceError? validator(String value) {
    // Solo validamos la longitud si se proporciona un valor
    if (value.length > 500) return ReferenceError.tooLong;
    return null; // Opcional, pero con validación básica
  }
}