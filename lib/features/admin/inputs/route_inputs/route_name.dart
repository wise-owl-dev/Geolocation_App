import 'package:formz/formz.dart';

// Define input validation errors for Route Name (nombre)
enum RouteNameError { empty }

// Class for Route Name validation
class RouteName extends FormzInput<String, RouteNameError> {
  // Constructor for unmodified value
  const RouteName.pure() : super.pure('');

  // Constructor for modified value
  const RouteName.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == RouteNameError.empty) return 'El nombre del recorrido es requerido';

    return null;
  }

  // Validation method
  @override
  RouteNameError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return RouteNameError.empty;

    return null;
  }
}