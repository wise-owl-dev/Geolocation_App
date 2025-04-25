import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus.dart';

class AddBusState {
  final bool isLoading;
  final Bus? bus;
  final bool isSuccess;
  final String? error;
  final String? errorCode;

  AddBusState({
    required this.isLoading,
    this.bus,
    required this.isSuccess,
    this.error,
    this.errorCode,
  });

  // Initial state
  factory AddBusState.initial() => AddBusState(
    isLoading: false,
    bus: null,
    isSuccess: false,
    error: null,
    errorCode: null,
  );

  // CopyWith method for immutability
  AddBusState copyWith({
    bool? isLoading,
    Bus? bus,
    bool? isSuccess,
    String? error,
    String? errorCode,
  }) {
    return AddBusState(
      isLoading: isLoading ?? this.isLoading,
      bus: bus ?? this.bus,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      errorCode: errorCode,
    );
  }
}

class AddBusNotifier extends StateNotifier<AddBusState> {
  final _supabase = Supabase.instance.client;

  AddBusNotifier() : super(AddBusState.initial());

  Future<void> createBus({
    required String busNumber,
    required String licensePlate,
    required int capacity,
    required String model,
    required String brand,
    required int year,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null, isSuccess: false);
    
    try {
      // Check if bus number already exists
      final busNumberExists = await _checkBusNumberExists(busNumber);
      if (busNumberExists) {
        throw Exception('Este número de unidad ya está registrado.');
      }
      
      // Check if license plate already exists
      final licensePlateExists = await _checkLicensePlateExists(licensePlate);
      if (licensePlateExists) {
        throw Exception('Esta placa ya está registrada.');
      }
      
      // Insert data into 'autobuses' table
      final result = await _supabase.from('autobuses').insert({
        'numero_unidad': busNumber,
        'placa': licensePlate,
        'capacidad': capacity,
        'modelo': model,
        'marca': brand,
        'año': year,
        'estado': status,
      }).select();
      
      if (result.isEmpty) {
        throw Exception('No se pudo crear el autobús. Intenta de nuevo.');
      }
      
      // Get the created bus data
      final busData = result[0];
      final createdBus = Bus.fromJson(busData);
      
      state = state.copyWith(
        isLoading: false, 
        bus: createdBus,
        isSuccess: true,
      );
    } catch (e) {
      String errorMessage = e.toString();
      String errorCode = 'unknown-error';
      
      state = state.copyWith(
        isLoading: false, 
        error: errorMessage,
        errorCode: errorCode,
        isSuccess: false,
      );
    }
  }
  
  // Helper method to check if bus number already exists
  Future<bool> _checkBusNumberExists(String busNumber) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select('numero_unidad')
          .eq('numero_unidad', busNumber);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking bus number: $e');
      return false;
    }
  }
  
  // Helper method to check if license plate already exists
  Future<bool> _checkLicensePlateExists(String licensePlate) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select('placa')
          .eq('placa', licensePlate);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking license plate: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null, errorCode: null);
  }
  
  void reset() {
    state = AddBusState.initial();
  }
}

final addBusProvider = StateNotifierProvider<AddBusNotifier, AddBusState>((ref) {
  return AddBusNotifier();
});