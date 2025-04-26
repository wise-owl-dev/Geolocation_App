import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../inputs/route_inputs/inputs.dart';

// Form state
class AddRouteFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final RouteName name;
  final RouteDescription description;
  final StartTime startTime;
  final EndTime endTime;
  final Days days;
  final RouteStatus status;

  AddRouteFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.name = const RouteName.pure(),
    this.description = const RouteDescription.pure(),
    this.startTime = const StartTime.pure(),
    this.endTime = const EndTime.pure(),
    this.days = const Days.pure(),
    this.status = const RouteStatus.pure(),
  });

  AddRouteFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    RouteName? name,
    RouteDescription? description,
    StartTime? startTime,
    EndTime? endTime,
    Days? days,
    RouteStatus? status,
  }) => AddRouteFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    name: name ?? this.name,
    description: description ?? this.description,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    days: days ?? this.days,
    status: status ?? this.status,
  );

  @override
  String toString() {
    return '''
  AddRouteFormState:
    isPosting: $isPosting
    isFormPosted: $isFormPosted
    isValid: $isValid
    name: $name
    description: $description
    startTime: $startTime
    endTime: $endTime
    days: $days
    status: $status
''';
  }
}

// Notifier implementation
class AddRouteFormNotifier extends StateNotifier<AddRouteFormState> {
  AddRouteFormNotifier() : super(AddRouteFormState());

  onNameChanged(String value) {
    final newName = RouteName.dirty(value);
    _validateForm(name: newName);
  }

  onDescriptionChanged(String value) {
    final newDescription = RouteDescription.dirty(value);
    _validateForm(description: newDescription);
  }
  
  onStartTimeChanged(String value) {
    final newStartTime = StartTime.dirty(value);
    // When start time changes, we might need to validate the end time again
    final newEndTime = EndTime.dirty(state.endTime.value, value);
    _validateForm(startTime: newStartTime, endTime: newEndTime);
  }
  
  onEndTimeChanged(String value) {
    final newEndTime = EndTime.dirty(value, state.startTime.value);
    _validateForm(endTime: newEndTime);
  }
  
  onDaysChanged(List<String> value) {
    final newDays = Days.dirty(value);
    _validateForm(days: newDays);
  }
  
  onStatusChanged(String value) {
    final newStatus = RouteStatus.dirty(value);
    _validateForm(status: newStatus);
  }

  // Method to validate the form
  void _validateForm({
    RouteName? name,
    RouteDescription? description,
    StartTime? startTime,
    EndTime? endTime,
    Days? days,
    RouteStatus? status,
  }) {
    // Create new instances or use current state
    name = name ?? state.name;
    description = description ?? state.description;
    startTime = startTime ?? state.startTime;
    endTime = endTime ?? state.endTime;
    days = days ?? state.days;
    status = status ?? state.status;
    
    // Update state with new values and validate
    state = state.copyWith(
      name: name,
      description: description,
      startTime: startTime,
      endTime: endTime,
      days: days,
      status: status,
      isValid: Formz.validate([
        name,
        startTime,
        endTime,
        days,
        status,
        // Description is optional
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
    final name = RouteName.dirty(state.name.value);
    final description = RouteDescription.dirty(state.description.value);
    final startTime = StartTime.dirty(state.startTime.value);
    final endTime = EndTime.dirty(state.endTime.value, state.startTime.value);
    final days = Days.dirty(state.days.value);
    final status = RouteStatus.dirty(state.status.value);

    state = state.copyWith(
      isFormPosted: true,
      name: name,
      description: description,
      startTime: startTime,
      endTime: endTime,
      days: days,
      status: status,
      isValid: Formz.validate([
        name,
        startTime,
        endTime,
        days,
        status,
        // Description is optional
      ]),
    );
  }
  
  Future<bool> onFormSubmitForEditing() async {
    _touchEveryField();
    return state.isValid;
  }
}

// StateNotifierProvider
final addRouteFormProvider = StateNotifierProvider.autoDispose<AddRouteFormNotifier, AddRouteFormState>((ref) {
  return AddRouteFormNotifier();
});