import 'package:formz/formz.dart';

// Define input validation errors for Brand (marca)
enum BrandError { empty }

// Class for Brand validation
class Brand extends FormzInput<String, BrandError> {
  // Constructor for unmodified value
  const Brand.pure() : super.pure('');

  // Constructor for modified value
  const Brand.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == BrandError.empty) return 'La marca es requerida';

    return null;
  }

  // Validation method
  @override
  BrandError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return BrandError.empty;

    return null;
  }
}