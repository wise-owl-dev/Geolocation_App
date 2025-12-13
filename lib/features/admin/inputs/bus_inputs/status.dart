import 'package:formz/formz.dart';

// Define input validation errors for Status (estado)
enum StatusError { empty, invalid }

// Class for Status validation
class Status extends FormzInput<String, StatusError> {
  // Valid status values
  static const List<String> validStatuses = ['activo', 'inactivo', 'mantenimiento'];

  // Constructor for unmodified value
  const Status.pure() : super.pure('activo');

  // Constructor for modified value
  const Status.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid ) return null;

    if (displayError == StatusError.empty) return 'El estado es requerido';
    if (displayError == StatusError.invalid) return 'El estado debe ser activo, inactivo o mantenimiento';

    return null;
  }

  // Validation method
  @override
  StatusError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return StatusError.empty;
    if (!validStatuses.contains(value)) return StatusError.invalid;

    return null;
  }
}