import 'package:formz/formz.dart';

// Define input validation errors for Model (modelo)
enum ModelError { empty }

// Class for Model validation
class Model extends FormzInput<String, ModelError> {
  // Constructor for unmodified value
  const Model.pure() : super.pure('');

  // Constructor for modified value
  const Model.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == ModelError.empty) return 'El modelo es requerido';

    return null;
  }

  // Validation method
  @override
  ModelError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return ModelError.empty;

    return null;
  }
}