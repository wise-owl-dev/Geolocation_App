import 'package:formz/formz.dart';

// Define input validation errors for Route Description (descripcion)
enum RouteDescriptionError { tooLong }

// Class for Route Description validation (optional field)
class RouteDescription extends FormzInput<String, RouteDescriptionError> {
  // Constructor for unmodified value
  const RouteDescription.pure() : super.pure('');

  // Constructor for modified value
  const RouteDescription.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;
    
    if (displayError == RouteDescriptionError.tooLong) return 'La descripción es demasiado larga';

    return null;
  }

  // Validation method
  @override
  RouteDescriptionError? validator(String value) {
    // Validate length if a value is provided
    if (value.length > 1000) return RouteDescriptionError.tooLong;
    return null; // Optional field with basic validation
  }
}