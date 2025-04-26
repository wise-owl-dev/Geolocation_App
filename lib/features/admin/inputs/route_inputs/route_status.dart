import 'package:formz/formz.dart';

// Define input validation errors for Route Status (estado)
enum RouteStatusError { empty, invalid }

// Class for Route Status validation
class RouteStatus extends FormzInput<String, RouteStatusError> {
  // Valid status values
  static const List<String> validStatuses = ['activo', 'inactivo'];

  // Constructor for unmodified value
  const RouteStatus.pure() : super.pure('activo');

  // Constructor for modified value
  const RouteStatus.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == RouteStatusError.empty) return 'El estado es requerido';
    if (displayError == RouteStatusError.invalid) return 'El estado debe ser activo o inactivo';

    return null;
  }

  // Validation method
  @override
  RouteStatusError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return RouteStatusError.empty;
    if (!validStatuses.contains(value)) return RouteStatusError.invalid;

    return null;
  }
}