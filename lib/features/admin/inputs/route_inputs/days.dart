import 'package:formz/formz.dart';

// Define input validation errors for Days (dias)
enum DaysError { empty }

// Class for Days validation
class Days extends FormzInput<List<String>, DaysError> {
  // Valid days of the week
  static const List<String> validDays = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];

  // Constructor for unmodified value
  const Days.pure() : super.pure(const []);

  // Constructor for modified value
  const Days.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == DaysError.empty) return 'Debe seleccionar al menos un día';

    return null;
  }

  // Validation method
  @override
  DaysError? validator(List<String> value) {
    if (value.isEmpty) return DaysError.empty;

    return null;
  }
}