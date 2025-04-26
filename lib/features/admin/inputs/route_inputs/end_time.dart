import 'package:formz/formz.dart';

// Define input validation errors for End Time (horario_fin)
enum EndTimeError { empty, format, beforeStart }

// Class for End Time validation
class EndTime extends FormzInput<String, EndTimeError> {
  // Regex for time format (HH:MM)
  static final RegExp timeRegExp = RegExp(
    r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
  );

  final String startTime;

  // Constructor for unmodified value
  const EndTime.pure([this.startTime = '']) : super.pure('');

  // Constructor for modified value
  const EndTime.dirty(String value, [this.startTime = '']) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == EndTimeError.empty) return 'La hora de fin es requerida';
    if (displayError == EndTimeError.format) return 'Formato de hora inválido (Use HH:MM)';
    if (displayError == EndTimeError.beforeStart) return 'La hora de fin debe ser posterior a la hora de inicio';

    return null;
  }

  // Validation method
  @override
  EndTimeError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return EndTimeError.empty;
    if (!timeRegExp.hasMatch(value)) return EndTimeError.format;

    // Only validate against start time if both are valid times
    if (startTime.isNotEmpty && timeRegExp.hasMatch(startTime)) {
      // Parse times to validate end is after start
      final startParts = startTime.split(':');
      final endParts = value.split(':');
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      // Compare hours and minutes
      if (endHour < startHour || (endHour == startHour && endMinute <= startMinute)) {
        return EndTimeError.beforeStart;
      }
    }

    return null;
  }
}