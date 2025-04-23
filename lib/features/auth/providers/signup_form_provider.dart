import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../../shared/inputs/inputs.dart';

//! 1 - State del provider
class SignUpFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Email email;
  final Password password;
  final Name name;
  final LastName lastName;
  final LastName maternalLastName;
  final Phone phone;

  SignUpFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.name = const Name.pure(),
    this.lastName = const LastName.pure(),
    this.maternalLastName = const LastName.pure(),
    this.phone = const Phone.pure(),
  });

  SignUpFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    Email? email,
    Password? password,
    Name? name,
    LastName? lastName,
    LastName? maternalLastName,
    Phone? phone,
  }) => SignUpFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    email: email ?? this.email,
    password: password ?? this.password,
    name: name ?? this.name,
    lastName: lastName ?? this.lastName,
    maternalLastName: maternalLastName ?? this.maternalLastName,
    phone: phone ?? this.phone,
  );

  @override
  String toString() {
    return '''
  SignUpFormState:
    isPosting: $isPosting
    isFormPosted: $isFormPosted
    isValid: $isValid
    email: $email
    password: $password
    name: $name
    lastName: $lastName
    maternalLastName: $maternalLastName
    phone: $phone
''';
  }
}

//! 2 - Como implementamos un notifier
class SignUpFormNotifier extends StateNotifier<SignUpFormState> {
  SignUpFormNotifier() : super(SignUpFormState());

  onEmailChange(String value) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([
        newEmail, 
        state.password,
        state.name,
        state.lastName,
        state.phone
      ]),
    );
  }

  onPasswordChanged(String value) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
      password: newPassword,
      isValid: Formz.validate([
        newPassword, 
        state.email,
        state.name,
        state.lastName,
        state.phone
      ]),
    );
  }
  
  onNameChanged(String value) {
    final newName = Name.dirty(value);
    state = state.copyWith(
      name: newName,
      isValid: Formz.validate([
        newName, 
        state.email,
        state.password,
        state.lastName,
        state.phone
      ]),
    );
  }
  
  onLastNameChanged(String value) {
    final newLastName = LastName.dirty(value);
    state = state.copyWith(
      lastName: newLastName,
      isValid: Formz.validate([
        newLastName, 
        state.email,
        state.password,
        state.name,
        state.phone
      ]),
    );
  }
  
  onMaternalLastNameChanged(String value) {
    final newMaternalLastName = LastName.dirty(value);
    state = state.copyWith(
      maternalLastName: newMaternalLastName,
      isValid: Formz.validate([
        state.email,
        state.password,
        state.name,
        state.lastName,
        state.phone
      ]), // Maternal last name is optional
    );
  }
  
  onPhoneChanged(String value) {
    final newPhone = Phone.dirty(value);
    state = state.copyWith(
      phone: newPhone,
      isValid: Formz.validate([
        newPhone, 
        state.email,
        state.password,
        state.name,
        state.lastName
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
    // Maternal last name is optional
    final maternalLastName = state.maternalLastName.value.isNotEmpty 
      ? LastName.dirty(state.maternalLastName.value)
      : const LastName.pure();

    state = state.copyWith(
      isFormPosted: true,
      email: email,
      password: password,
      name: name,
      lastName: lastName,
      maternalLastName: maternalLastName,
      phone: phone,
      isValid: Formz.validate([email, password, name, lastName, phone]),
    );
  }
}

//! 3 - StateNotifierProvider - consume afuera
final signUpFormProvider = StateNotifierProvider.autoDispose<SignUpFormNotifier, SignUpFormState>((ref) {
  return SignUpFormNotifier();
});