import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/bus_stop.dart';

class AddBusStopState {
  final bool isLoading;
  final BusStop? busStop;
  final bool isSuccess;
  final String? error;
  final String? errorCode;

  AddBusStopState({
    required this.isLoading,
    this.busStop,
    required this.isSuccess,
    this.error,
    this.errorCode,
  });

  // Initial state
  factory AddBusStopState.initial() => AddBusStopState(
    isLoading: false,
    busStop: null,
    isSuccess: false,
    error: null,
    errorCode: null,
  );

  // CopyWith method for immutability
  AddBusStopState copyWith({
    bool? isLoading,
    BusStop? busStop,
    bool? isSuccess,
    String? error,
    String? errorCode,
  }) {
    return AddBusStopState(
      isLoading: isLoading ?? this.isLoading,
      busStop: busStop ?? this.busStop,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      errorCode: errorCode,
    );
  }
}

class AddBusStopNotifier extends StateNotifier<AddBusStopState> {
  final _supabase = Supabase.instance.client;

  AddBusStopNotifier() : super(AddBusStopState.initial());

  Future<void> createBusStop({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? reference,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null, isSuccess: false);
    
    try {
      // Insert data into 'paradas' table
      final result = await _supabase.from('paradas').insert({
        'nombre': name,
        'latitud': latitude,
        'longitud': longitude,
        'direccion': address,
        'referencia': reference,
        'estado': status,
      }).select();
      
      if (result.isEmpty) {
        throw Exception('No se pudo crear la parada. Intenta de nuevo.');
      }
      
      // Get the created bus stop data
      final busStopData = result[0];
      final createdBusStop = BusStop.fromJson(busStopData);
      
      state = state.copyWith(
        isLoading: false, 
        busStop: createdBusStop,
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

  void clearError() {
    state = state.copyWith(error: null, errorCode: null);
  }
  
  void reset() {
    state = AddBusStopState.initial();
  }
}

final addBusStopProvider = StateNotifierProvider<AddBusStopNotifier, AddBusStopState>((ref) {
  return AddBusStopNotifier();
});