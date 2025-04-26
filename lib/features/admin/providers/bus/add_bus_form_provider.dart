import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../inputs/bus_inputs/inputs.dart';

// Form state
class AddBusFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final BusNumber busNumber;
  final LicensePlate licensePlate;
  final Capacity capacity;
  final Model model;
  final Brand brand;
  final Year year;
  final Status status;

  AddBusFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.busNumber = const BusNumber.pure(),
    this.licensePlate = const LicensePlate.pure(),
    this.capacity = const Capacity.pure(),
    this.model = const Model.pure(),
    this.brand = const Brand.pure(),
    this.year = const Year.pure(),
    this.status = const Status.pure(),
  });

  AddBusFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    BusNumber? busNumber,
    LicensePlate? licensePlate,
    Capacity? capacity,
    Model? model,
    Brand? brand,
    Year? year,
    Status? status,
  }) => AddBusFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    busNumber: busNumber ?? this.busNumber,
    licensePlate: licensePlate ?? this.licensePlate,
    capacity: capacity ?? this.capacity,
    model: model ?? this.model,
    brand: brand ?? this.brand,
    year: year ?? this.year,
    status: status ?? this.status,
  );

  @override
  String toString() {
    return '''
  AddBusFormState:
    isPosting: $isPosting
    isFormPosted: $isFormPosted
    isValid: $isValid
    busNumber: $busNumber
    licensePlate: $licensePlate
    capacity: $capacity
    model: $model
    brand: $brand
    year: $year
    status: $status
''';
  }
}

// Notifier implementation
class AddBusFormNotifier extends StateNotifier<AddBusFormState> {
  AddBusFormNotifier() : super(AddBusFormState());

  onBusNumberChanged(String value) {
    final newBusNumber = BusNumber.dirty(value);
    _validateForm(busNumber: newBusNumber);
  }

  onLicensePlateChanged(String value) {
    final newLicensePlate = LicensePlate.dirty(value);
    _validateForm(licensePlate: newLicensePlate);
  }
  
  onCapacityChanged(String value) {
    final newCapacity = Capacity.dirty(value);
    _validateForm(capacity: newCapacity);
  }
  
  onModelChanged(String value) {
    final newModel = Model.dirty(value);
    _validateForm(model: newModel);
  }
  
  onBrandChanged(String value) {
    final newBrand = Brand.dirty(value);
    _validateForm(brand: newBrand);
  }
  
  onYearChanged(String value) {
    final newYear = Year.dirty(value);
    _validateForm(year: newYear);
  }
  
  onStatusChanged(String value) {
    final newStatus = Status.dirty(value);
    _validateForm(status: newStatus);
  }

  // Method to validate the form
  void _validateForm({
    BusNumber? busNumber,
    LicensePlate? licensePlate,
    Capacity? capacity,
    Model? model,
    Brand? brand,
    Year? year,
    Status? status,
  }) {
    // Create new instances or use current state
    busNumber = busNumber ?? state.busNumber;
    licensePlate = licensePlate ?? state.licensePlate;
    capacity = capacity ?? state.capacity;
    model = model ?? state.model;
    brand = brand ?? state.brand;
    year = year ?? state.year;
    status = status ?? state.status;
    
    // Update state with new values and validate
    state = state.copyWith(
      busNumber: busNumber,
      licensePlate: licensePlate,
      capacity: capacity,
      model: model,
      brand: brand,
      year: year,
      status: status,
      isValid: Formz.validate([
        busNumber,
        licensePlate,
        capacity,
        model,
        brand,
        year,
        status,
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
    final busNumber = BusNumber.dirty(state.busNumber.value);
    final licensePlate = LicensePlate.dirty(state.licensePlate.value);
    final capacity = Capacity.dirty(state.capacity.value);
    final model = Model.dirty(state.model.value);
    final brand = Brand.dirty(state.brand.value);
    final year = Year.dirty(state.year.value);
    final status = Status.dirty(state.status.value);

    state = state.copyWith(
      isFormPosted: true,
      busNumber: busNumber,
      licensePlate: licensePlate,
      capacity: capacity,
      model: model,
      brand: brand,
      year: year,
      status: status,
      isValid: Formz.validate([
        busNumber,
        licensePlate,
        capacity,
        model,
        brand,
        year,
        status,
      ]),
    );
  }
  
  void onFormSubmitForEdit() {
    // In edit mode, we might not need to validate some fields like busNumber and licensePlate
    final busNumber = BusNumber.dirty(state.busNumber.value);
    final licensePlate = LicensePlate.dirty(state.licensePlate.value);
    final capacity = Capacity.dirty(state.capacity.value);
    final model = Model.dirty(state.model.value);
    final brand = Brand.dirty(state.brand.value);
    final year = Year.dirty(state.year.value);
    final status = Status.dirty(state.status.value);

    state = state.copyWith(
      isFormPosted: true,
      busNumber: busNumber,
      licensePlate: licensePlate,
      capacity: capacity,
      model: model,
      brand: brand,
      year: year,
      status: status,
      isValid: Formz.validate([
        capacity,
        model,
        brand,
        year,
        status,
      ]),
    );
  }

  Future<bool> onFormSubmitForEditing() async {
    onFormSubmitForEdit();
    return state.isValid;
  }
}

// StateNotifierProvider
final addBusFormProvider = StateNotifierProvider.autoDispose<AddBusFormNotifier, AddBusFormState>((ref) {
  return AddBusFormNotifier();
});