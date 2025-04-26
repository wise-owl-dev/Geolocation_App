import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import '../../inputs/busstop_inputs/inputs.dart';

// Form state
class AddBusStopFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final BusStopName name;
  final Latitude latitude;
  final Longitude longitude;
  final Address address;
  final Reference reference;
  final BusStopStatus status;

  AddBusStopFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.name = const BusStopName.pure(),
    this.latitude = const Latitude.pure(),
    this.longitude = const Longitude.pure(),
    this.address = const Address.pure(),
    this.reference = const Reference.pure(),
    this.status = const BusStopStatus.pure(),
  });

  AddBusStopFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    BusStopName? name,
    Latitude? latitude,
    Longitude? longitude,
    Address? address,
    Reference? reference,
    BusStopStatus? status,
  }) => AddBusStopFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    address: address ?? this.address,
    reference: reference ?? this.reference,
    status: status ?? this.status,
  );

  @override
  String toString() {
    return '''
  AddBusStopFormState:
    isPosting: $isPosting
    isFormPosted: $isFormPosted
    isValid: $isValid
    name: $name
    latitude: $latitude
    longitude: $longitude
    address: $address
    reference: $reference
    status: $status
''';
  }
}

// Notifier implementation
class AddBusStopFormNotifier extends StateNotifier<AddBusStopFormState> {
  AddBusStopFormNotifier() : super(AddBusStopFormState());

  onNameChanged(String value) {
    final newName = BusStopName.dirty(value);
    _validateForm(name: newName);
  }

  onLatitudeChanged(String value) {
    final newLatitude = Latitude.dirty(value);
    _validateForm(latitude: newLatitude);
  }
  
  onLongitudeChanged(String value) {
    final newLongitude = Longitude.dirty(value);
    _validateForm(longitude: newLongitude);
  }
  
  onAddressChanged(String value) {
    final newAddress = Address.dirty(value);
    _validateForm(address: newAddress);
  }
  
  onReferenceChanged(String value) {
    final newReference = Reference.dirty(value);
    _validateForm(reference: newReference);
  }
  
  onStatusChanged(String value) {
    final newStatus = BusStopStatus.dirty(value);
    _validateForm(status: newStatus);
  }

  // Method to validate the form
  void _validateForm({
    BusStopName? name,
    Latitude? latitude,
    Longitude? longitude,
    Address? address,
    Reference? reference,
    BusStopStatus? status,
  }) {
    // Create new instances or use current state
    name = name ?? state.name;
    latitude = latitude ?? state.latitude;
    longitude = longitude ?? state.longitude;
    address = address ?? state.address;
    reference = reference ?? state.reference;
    status = status ?? state.status;
    
    // Update state with new values and validate
    state = state.copyWith(
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      reference: reference,
      status: status,
      isValid: Formz.validate([
        name,
        latitude,
        longitude,
        status,
        // Address and reference are optional
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
    final name = BusStopName.dirty(state.name.value);
    final latitude = Latitude.dirty(state.latitude.value);
    final longitude = Longitude.dirty(state.longitude.value);
    final address = Address.dirty(state.address.value);
    final reference = Reference.dirty(state.reference.value);
    final status = BusStopStatus.dirty(state.status.value);

    state = state.copyWith(
      isFormPosted: true,
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      reference: reference,
      status: status,
      isValid: Formz.validate([
        name,
        latitude,
        longitude,
        status,
        // Address and reference are optional
      ]),
    );
  }
  
  Future<bool> onFormSubmitForEditing() async {
    _touchEveryField();
    return state.isValid;
  }
}

// StateNotifierProvider
final addBusStopFormProvider = StateNotifierProvider.autoDispose<AddBusStopFormNotifier, AddBusStopFormState>((ref) {
  return AddBusStopFormNotifier();
});