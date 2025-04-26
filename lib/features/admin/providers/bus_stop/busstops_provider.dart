import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/bus_stop.dart';

class BusStopsState {
  final bool isLoading;
  final List<BusStop> busStops;
  final String? error;

  BusStopsState({
    required this.isLoading,
    required this.busStops,
    this.error,
  });

  // Initial state
  factory BusStopsState.initial() => BusStopsState(
    isLoading: false,
    busStops: [],
    error: null,
  );

  // CopyWith method for immutability
  BusStopsState copyWith({
    bool? isLoading,
    List<BusStop>? busStops,
    String? error,
  }) {
    return BusStopsState(
      isLoading: isLoading ?? this.isLoading,
      busStops: busStops ?? this.busStops,
      error: error,
    );
  }
}

class BusStopsNotifier extends StateNotifier<BusStopsState> {
  final _supabase = Supabase.instance.client;

  BusStopsNotifier() : super(BusStopsState.initial());

  // Method to load all bus stops
  Future<void> loadBusStops() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Query all bus stops
      final result = await _supabase
          .from('paradas')
          .select()
          .order('nombre', ascending: true);
      
      print('Query result: $result');
      
      if (result.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          busStops: [],
        );
        return;
      }
      
      // Transform data into BusStop objects
      final List<BusStop> busStops = [];
      
      for (var busStopData in result) {
        try {
          print('Processing bus stop: $busStopData');
          final busStop = BusStop.fromJson(busStopData);
          busStops.add(busStop);
          print('Bus stop added successfully');
        } catch (e) {
          print('Error processing bus stop: $e');
          // Continue with the next one
        }
      }
      
      print('Total bus stops processed: ${busStops.length}');
      
      state = state.copyWith(
        isLoading: false,
        busStops: busStops,
      );
    } catch (e) {
      print('Error loading bus stops: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar paradas: $e',
      );
    }
  }
  
  // Method to delete a bus stop
  Future<void> deleteBusStop(String busStopId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('Deleting bus stop with ID: $busStopId');
      
      // Delete from 'paradas' table
      await _supabase
          .from('paradas')
          .delete()
          .eq('id', busStopId);
      
      print('Bus stop deleted successfully');
      
      // Update local state
      final updatedBusStops = state.busStops.where((busStop) => busStop.id != busStopId).toList();
      
      state = state.copyWith(
        isLoading: false,
        busStops: updatedBusStops,
      );
    } catch (e) {
      print('Error deleting bus stop: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar la parada: $e',
      );
    }
  }

  // Method to refresh the list after adding a new bus stop
  void refreshAfterAdd() {
    loadBusStops();
  }
}

final busStopsProvider = StateNotifierProvider<BusStopsNotifier, BusStopsState>((ref) {
  return BusStopsNotifier();
});