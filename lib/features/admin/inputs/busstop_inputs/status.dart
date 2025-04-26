import 'package:formz/formz.dart';

// Define input validation errors for Status (estado)
enum BusStopStatusError { empty, invalid }

// Class for Status validation
class BusStopStatus extends FormzInput<String, BusStopStatusError> {
  // Valid status values
  static const List<String> validStatuses = ['activo', 'inactivo'];

  // Constructor for unmodified value
  const BusStopStatus.pure() : super.pure('activo');

  // Constructor for modified value
  const BusStopStatus.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == BusStopStatusError.empty) return 'El estado es requerido';
    if (displayError == BusStopStatusError.invalid) return 'El estado debe ser activo o inactivo';

    return null;
  }

  // Validation method
  @override
  BusStopStatusError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return BusStopStatusError.empty;
    if (!validStatuses.contains(value)) return BusStopStatusError.invalid;

    return null;
  }
}