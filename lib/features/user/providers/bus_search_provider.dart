import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus.dart';

class BusSearchState {
  final bool isLoading;
  final List<Bus> buses;
  final String? error;
  final String searchQuery;

  BusSearchState({
    required this.isLoading,
    required this.buses,
    this.error,
    required this.searchQuery,
  });

  // Estado inicial
  factory BusSearchState.initial() => BusSearchState(
    isLoading: false,
    buses: [],
    error: null,
    searchQuery: '',
  );

  // Método copyWith para inmutabilidad
  BusSearchState copyWith({
    bool? isLoading,
    List<Bus>? buses,
    String? error,
    String? searchQuery,
  }) {
    return BusSearchState(
      isLoading: isLoading ?? this.isLoading,
      buses: buses ?? this.buses,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BusSearchNotifier extends StateNotifier<BusSearchState> {
  final _supabase = Supabase.instance.client;

  BusSearchNotifier() : super(BusSearchState.initial());

  // Método para buscar autobuses por número de unidad
  Future<void> searchBusByNumber(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        buses: [],
        searchQuery: '',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    
    try {
      // Buscar autobuses que coincidan con el query
      final result = await _supabase
          .from('autobuses')
          .select()
          .ilike('numero_unidad', '%$query%')
          .order('numero_unidad');
      
      // Transformar datos en objetos Bus
      final List<Bus> buses = [];
      for (var busData in result) {
        try {
          buses.add(Bus.fromJson(busData));
        } catch (e) {
          print('Error procesando autobús: $e');
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        buses: buses,
      );
    } catch (e) {
      print('Error buscando autobuses: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar autobuses: $e',
      );
    }
  }

  // Método para obtener la lista completa de autobuses
  Future<void> loadAllBuses() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Obtener todos los autobuses
      final result = await _supabase
          .from('autobuses')
          .select()
          .eq('estado', 'activo')
          .order('numero_unidad');
      
      // Transformar datos en objetos Bus
      final List<Bus> buses = [];
      for (var busData in result) {
        try {
          buses.add(Bus.fromJson(busData));
        } catch (e) {
          print('Error procesando autobús: $e');
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        buses: buses,
      );
    } catch (e) {
      print('Error cargando autobuses: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar autobuses: $e',
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(
      buses: [],
      searchQuery: '',
    );
  }
}

final busSearchProvider = StateNotifierProvider<BusSearchNotifier, BusSearchState>((ref) {
  return BusSearchNotifier();
});