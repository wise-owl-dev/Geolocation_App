import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/bus.dart';

class EditBusState {
  final bool isLoading;
  final Bus? bus;
  final bool isSuccess;
  final String? error;

  EditBusState({
    required this.isLoading,
    this.bus,
    required this.isSuccess,
    this.error,
  });

  // Initial state
  factory EditBusState.initial() => EditBusState(
    isLoading: false,
    bus: null,
    isSuccess: false,
    error: null,
  );

  // CopyWith method for immutability
  EditBusState copyWith({
    bool? isLoading,
    Bus? bus,
    bool? isSuccess,
    String? error,
  }) {
    return EditBusState(
      isLoading: isLoading ?? this.isLoading,
      bus: bus ?? this.bus,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class EditBusNotifier extends StateNotifier<EditBusState> {
  final _supabase = Supabase.instance.client;

  EditBusNotifier() : super(EditBusState.initial());

  // Method to load a specific bus data
  Future<void> loadBus(String busId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      // Query the bus data
      final result = await _supabase
          .from('autobuses')
          .select()
          .eq('id', busId)
          .single();
      
      print('Bus data: $result');
      
      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se encontraron datos del autobús',
        );
        return;
      }
      
      // Create Bus object
      final bus = Bus.fromJson(result);
      
      state = state.copyWith(
        isLoading: false,
        bus: bus,
      );
    } catch (e) {
      print('Error loading bus: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los datos del autobús: $e',
      );
    }
  }
  
  // Method to update a bus
  Future<void> updateBus({
    required String busId,
    required String busNumber,
    required String licensePlate,
    required int capacity,
    required String model,
    required String brand,
    required int year,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      print('Updating bus $busId');
      
      // Update data in 'autobuses' table
      await _supabase
          .from('autobuses')
          .update({
            'numero_unidad': busNumber,
            'placa': licensePlate,
            'capacidad': capacity,
            'modelo': model,
            'marca': brand,
            'año': year,
            'estado': status,
          })
          .eq('id', busId);
      
      print('Bus updated successfully');
      
      // Mark as success
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      print('Error updating bus: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar el autobús: $e',
        isSuccess: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void reset() {
    state = EditBusState.initial();
  }
}

final editBusProvider = StateNotifierProvider<EditBusNotifier, EditBusState>((ref) {
  return EditBusNotifier();
});