import 'package:formz/formz.dart';

// Define input validation errors for Start Time (horario_inicio)
enum StartTimeError { empty, format }

// Class for Start Time validation
class StartTime extends FormzInput<String, StartTimeError> {
  // Regex for time format (HH:MM)
  static final RegExp timeRegExp = RegExp(
    r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
  );

  // Constructor for unmodified value
  const StartTime.pure() : super.pure('');

  // Constructor for modified value
  const StartTime.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == StartTimeError.empty) return 'La hora de inicio es requerida';
    if (displayError == StartTimeError.format) return 'Formato de hora inválido (Use HH:MM)';

    return null;
  }

  // Validation method
  @override
  StartTimeError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return StartTimeError.empty;
    if (!timeRegExp.hasMatch(value)) return StartTimeError.format;

    return null;
  }
}