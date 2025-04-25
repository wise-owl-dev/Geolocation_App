import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus.dart';

class BusesState {
  final bool isLoading;
  final List<Bus> buses;
  final String? error;

  BusesState({
    required this.isLoading,
    required this.buses,
    this.error,
  });

  // Initial state
  factory BusesState.initial() => BusesState(
    isLoading: false,
    buses: [],
    error: null,
  );

  // CopyWith method for immutability
  BusesState copyWith({
    bool? isLoading,
    List<Bus>? buses,
    String? error,
  }) {
    return BusesState(
      isLoading: isLoading ?? this.isLoading,
      buses: buses ?? this.buses,
      error: error,
    );
  }
}

class BusesNotifier extends StateNotifier<BusesState> {
  final _supabase = Supabase.instance.client;

  BusesNotifier() : super(BusesState.initial());

  // Method to load all buses
  Future<void> loadBuses() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Query all buses
      final result = await _supabase
          .from('autobuses')
          .select()
          .order('numero_unidad', ascending: true);
      
      print('Query result: $result');
      
      if (result.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          buses: [],
        );
        return;
      }
      
      // Transform data into Bus objects
      final List<Bus> buses = [];
      
      for (var busData in result) {
        try {
          print('Processing bus: $busData');
          final bus = Bus.fromJson(busData);
          buses.add(bus);
          print('Bus added successfully');
        } catch (e) {
          print('Error processing bus: $e');
          // Continue with the next one
        }
      }
      
      print('Total buses processed: ${buses.length}');
      
      state = state.copyWith(
        isLoading: false,
        buses: buses,
      );
    } catch (e) {
      print('Error loading buses: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar autobuses: $e',
      );
    }
  }
  
  // Method to delete a bus
  Future<void> deleteBus(String busId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('Deleting bus with ID: $busId');
      
      // Delete from 'autobuses' table
      await _supabase
          .from('autobuses')
          .delete()
          .eq('id', busId);
      
      print('Bus deleted successfully');
      
      // Update local state
      final updatedBuses = state.buses.where((bus) => bus.id != busId).toList();
      
      state = state.copyWith(
        isLoading: false,
        buses: updatedBuses,
      );
    } catch (e) {
      print('Error deleting bus: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar el autobús: $e',
      );
    }
  }

  // Method to refresh the list after adding a new bus
  void refreshAfterAdd() {
    loadBuses();
  }
}

final busesProvider = StateNotifierProvider<BusesNotifier, BusesState>((ref) {
  return BusesNotifier();
});