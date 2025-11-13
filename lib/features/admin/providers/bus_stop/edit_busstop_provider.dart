import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/bus_stop.dart';

class EditBusStopState {
  final bool isLoading;
  final BusStop? busStop;
  final bool isSuccess;
  final String? error;

  EditBusStopState({
    required this.isLoading,
    this.busStop,
    required this.isSuccess,
    this.error,
  });

  // Initial state
  factory EditBusStopState.initial() => EditBusStopState(
    isLoading: false,
    busStop: null,
    isSuccess: false,
    error: null,
  );

  // CopyWith method for immutability
  EditBusStopState copyWith({
    bool? isLoading,
    BusStop? busStop,
    bool? isSuccess,
    String? error,
  }) {
    return EditBusStopState(
      isLoading: isLoading ?? this.isLoading,
      busStop: busStop ?? this.busStop,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class EditBusStopNotifier extends StateNotifier<EditBusStopState> {
  final _supabase = Supabase.instance.client;

  EditBusStopNotifier() : super(EditBusStopState.initial());

  // Method to load a specific bus stop data
  Future<void> loadBusStop(String busStopId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      // Query the bus stop data
      final result = await _supabase
          .from('paradas')
          .select()
          .eq('id', busStopId)
          .single();
      
      print('Bus stop data: $result');
      
      // Create BusStop object
      final busStop = BusStop.fromJson(result);
      
      state = state.copyWith(
        isLoading: false,
        busStop: busStop,
      );
    } catch (e) {
      print('Error loading bus stop: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los datos de la parada: $e',
      );
    }
  }
  
  // Method to update a bus stop
  Future<void> updateBusStop({
    required String busStopId,
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? reference,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      print('Updating bus stop $busStopId');
      
      // Update data in 'paradas' table
      await _supabase
          .from('paradas')
          .update({
            'nombre': name,
            'latitud': latitude,
            'longitud': longitude,
            'direccion': address,
            'referencia': reference,
            'estado': status,
          })
          .eq('id', busStopId);
      
      print('Bus stop updated successfully');
      
      // Mark as success
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      print('Error updating bus stop: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar la parada: $e',
        isSuccess: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void reset() {
    state = EditBusStopState.initial();
  }
}

final editBusStopProvider = StateNotifierProvider<EditBusStopNotifier, EditBusStopState>((ref) {
  return EditBusStopNotifier();
});