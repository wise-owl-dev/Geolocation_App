// lib/features/admin/providers/add_operator_form_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../../auth/inputs/inputs.dart';
import '../../inputs/operator_inputs/inputs.dart';

//! 1 - State del provider
class AddOperatorFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Email email;
  final Password password;
  final Name name;
  final LastName lastName;
  final LastName maternalLastName;
  final Phone phone;
  // Campos específicos para operadores
  final LicenseNumber licenseNumber;
  final LicenseType licenseType;
  final YearsExperience yearsExperience;
  final DateTime hireDate;

  AddOperatorFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.name = const Name.pure(),
    this.lastName = const LastName.pure(),
    this.maternalLastName = const LastName.pure(),
    this.phone = const Phone.pure(),
    // Inicializar campos de operador
    this.licenseNumber = const LicenseNumber.pure(),
    this.licenseType = const LicenseType.pure(),
    this.yearsExperience = const YearsExperience.pure(),
    DateTime? hireDate,
  }) : this.hireDate = hireDate ?? DateTime.now();

  AddOperatorFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    Email? email,
    Password? password,
    Name? name,
    LastName? lastName,
    LastName? maternalLastName,
    Phone? phone,
    // Campos de operador
    LicenseNumber? licenseNumber,
    LicenseType? licenseType,
    YearsExperience? yearsExperience,
    DateTime? hireDate,
  }) => AddOperatorFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    email: email ?? this.email,
    password: password ?? this.password,
    name: name ?? this.name,
    lastName: lastName ?? this.lastName,
    maternalLastName: maternalLastName ?? this.maternalLastName,
    phone: phone ?? this.phone,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    licenseType: licenseType ?? this.licenseType,
    yearsExperience: yearsExperience ?? this.yearsExperience,
    hireDate: hireDate ?? this.hireDate,
  );

  @override
  String toString() {
    return '''
  AddOperatorFormState:
    isPosting: $isPosting
    isFormPosted: $isFormPosted
    isValid: $isValid
    email: $email
    password: $password
    name: $name
    lastName: $lastName
    maternalLastName: $maternalLastName
    phone: $phone
    licenseNumber: $licenseNumber
    licenseType: $licenseType
    yearsExperience: $yearsExperience
    hireDate: $hireDate
''';
  }
}

//! 2 - Como implementamos un notifier
class AddOperatorFormNotifier extends StateNotifier<AddOperatorFormState> {
  AddOperatorFormNotifier() : super(AddOperatorFormState());

  onEmailChange(String value) {
    final newEmail = Email.dirty(value);
    _validateForm(email: newEmail);
  }

  onPasswordChanged(String value) {
    final newPassword = Password.dirty(value);
    _validateForm(password: newPassword);
  }
  
  onNameChanged(String value) {
    final newName = Name.dirty(value);
    _validateForm(name: newName);
  }
  
  onLastNameChanged(String value) {
    final newLastName = LastName.dirty(value);
    _validateForm(lastName: newLastName);
  }
  
  onMaternalLastNameChanged(String value) {
    final newMaternalLastName = LastName.dirty(value);
    // El apellido materno es opcional
    state = state.copyWith(
      maternalLastName: newMaternalLastName,
    );
  }
  
  onPhoneChanged(String value) {
    final newPhone = Phone.dirty(value);
    _validateForm(phone: newPhone);
  }
  
  // Métodos para campos específicos de operador
  onLicenseNumberChanged(String value) {
    final newLicenseNumber = LicenseNumber.dirty(value);
    _validateForm(licenseNumber: newLicenseNumber);
  }
  
  onLicenseTypeChanged(String value) {
    final newLicenseType = LicenseType.dirty(value);
    _validateForm(licenseType: newLicenseType);
  }
  
  onYearsExperienceChanged(String value) {
    final newYearsExperience = YearsExperience.dirty(value);
    _validateForm(yearsExperience: newYearsExperience);
  }
  
  onHireDateChanged(DateTime value) {
    state = state.copyWith(
      hireDate: value,
    );
    // No validamos aquí para evitar errores en carga inicial
  }

  // Método auxiliar para validar el formulario
  void _validateForm({
    Email? email,
    Password? password,
    Name? name,
    LastName? lastName,
    Phone? phone,
    LicenseNumber? licenseNumber,
    LicenseType? licenseType,
    YearsExperience? yearsExperience,
  }) {
    // Crear nuevas instancias o usar estado actual
    email = email ?? state.email;
    password = password ?? state.password;
    name = name ?? state.name;
    lastName = lastName ?? state.lastName;
    phone = phone ?? state.phone;
    licenseNumber = licenseNumber ?? state.licenseNumber;
    licenseType = licenseType ?? state.licenseType;
    yearsExperience = yearsExperience ?? state.yearsExperience;
    
    // Actualizar estado con nuevos valores y validar
    state = state.copyWith(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
      phone: phone,
      licenseNumber: licenseNumber,
      licenseType: licenseType,
      yearsExperience: yearsExperience,
      isValid: Formz.validate([
        email,
        password,
        name,
        lastName,
        phone,
        licenseNumber,
        licenseType,
        yearsExperience,
      ]),
    );
  }

  onFormSubmit() async {
    _touchEveryField();

    if (!state.isValid) return false;

    print(state.toString());
    return true;
  }

  _touchEveryField() {
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final name = Name.dirty(state.name.value);
    final lastName = LastName.dirty(state.lastName.value);
    final phone = Phone.dirty(state.phone.value);
    // El apellido materno es opcional
    final maternalLastName = state.maternalLastName.value.isNotEmpty 
      ? LastName.dirty(state.maternalLastName.value)
      : const LastName.pure();
    final licenseNumber = LicenseNumber.dirty(state.licenseNumber.value);
    final licenseType = LicenseType.dirty(state.licenseType.value);
    final yearsExperience = YearsExperience.dirty(state.yearsExperience.value);

    state = state.copyWith(
      isFormPosted: true,
      email: email,
      password: password,
      name: name,
      lastName: lastName,
      maternalLastName: maternalLastName,
      phone: phone,
      licenseNumber: licenseNumber,
      licenseType: licenseType,
      yearsExperience: yearsExperience,
      isValid: Formz.validate([
        email, 
        password, 
        name, 
        lastName, 
        phone,
        licenseNumber,
        licenseType,
        yearsExperience,
      ]),
    );
  }
  
  void onFormSubmitForEdit() {
    // No necesitamos validar email, password o license number en modo edición
    final name = Name.dirty(state.name.value);
    final lastName = LastName.dirty(state.lastName.value);
    final phone = Phone.dirty(state.phone.value);
    // El apellido materno es opcional
    final maternalLastName = state.maternalLastName.value.isNotEmpty 
      ? LastName.dirty(state.maternalLastName.value)
      : const LastName.pure();
    final licenseType = LicenseType.dirty(state.licenseType.value);
    final yearsExperience = YearsExperience.dirty(state.yearsExperience.value);

    state = state.copyWith(
      isFormPosted: true,
      name: name,
      lastName: lastName,
      maternalLastName: maternalLastName,
      phone: phone,
      licenseType: licenseType,
      yearsExperience: yearsExperience,
      isValid: Formz.validate([
        name, 
        lastName, 
        phone,
        licenseType,
        yearsExperience,
      ]),
    );
  }

  Future<bool> onFormSubmitForEditing() async {
    onFormSubmitForEdit();
    return state.isValid;
  }
}

//! 3 - StateNotifierProvider - consume afuera
final addOperatorFormProvider = StateNotifierProvider.autoDispose<AddOperatorFormNotifier, AddOperatorFormState>((ref) {
  return AddOperatorFormNotifier();
});