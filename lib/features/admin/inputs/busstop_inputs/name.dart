import 'package:formz/formz.dart';

// Define input validation errors for BusStop Name (nombre)
enum BusStopNameError { empty }

// Class for BusStop Name validation
class BusStopName extends FormzInput<String, BusStopNameError> {
  // Constructor for unmodified value
  const BusStopName.pure() : super.pure('');

  // Constructor for modified value
  const BusStopName.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == BusStopNameError.empty) return 'El nombre de la parada es requerido';

    return null;
  }

  // Validation method
  @override
  BusStopNameError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return BusStopNameError.empty;

    return null;
  }
}