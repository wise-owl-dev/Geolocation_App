import 'package:formz/formz.dart';

// Define input validation errors for Address (direccion)
enum AddressError { tooLong } // Añadimos un valor al enum

// Class for Address validation (optional field)
class Address extends FormzInput<String, AddressError> {
  // Constructor for unmodified value
  const Address.pure() : super.pure('');

  // Constructor for modified value
  const Address.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;
    
    if (displayError == AddressError.tooLong) return 'La dirección es demasiado larga';

    return null;
  }

  // Validation method
  @override
  AddressError? validator(String value) {
    // Solo validamos la longitud si se proporciona un valor
    if (value.length > 500) return AddressError.tooLong;
    return null; // Opcional, pero con validación básica
  }
}