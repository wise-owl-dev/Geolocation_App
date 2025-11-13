import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/route.dart' as app_route;

class EditRouteState {
  final bool isLoading;
  final app_route.Route? route;
  final bool isSuccess;
  final String? error;

  EditRouteState({
    required this.isLoading,
    this.route,
    required this.isSuccess,
    this.error,
  });

  // Initial state
  factory EditRouteState.initial() => EditRouteState(
    isLoading: false,
    route: null,
    isSuccess: false,
    error: null,
  );

  // CopyWith method for immutability
  EditRouteState copyWith({
    bool? isLoading,
    app_route.Route? route,
    bool? isSuccess,
    String? error,
  }) {
    return EditRouteState(
      isLoading: isLoading ?? this.isLoading,
      route: route ?? this.route,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class EditRouteNotifier extends StateNotifier<EditRouteState> {
  final _supabase = Supabase.instance.client;

  EditRouteNotifier() : super(EditRouteState.initial());

  // Method to load a specific route data
  Future<void> loadRoute(String routeId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      // Query the route data
      final result = await _supabase
          .from('recorridos')
          .select()
          .eq('id', routeId)
          .single();
      
      print('Route data: $result');
      
      // Create Route object
      final route = app_route.Route.fromJson(result);
      
      state = state.copyWith(
        isLoading: false,
        route: route,
      );
    } catch (e) {
      print('Error loading route: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los datos del recorrido: $e',
      );
    }
  }
  
  // Method to update a route
  Future<void> updateRoute({
    required String routeId,
    required String name,
    String? description,
    required String startTime,
    required String endTime,
    required List<String> days,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      print('Updating route $routeId');
      
      // Update data in 'recorridos' table
      await _supabase
          .from('recorridos')
          .update({
            'nombre': name,
            'descripcion': description,
            'horario_inicio': startTime,
            'horario_fin': endTime,
            'dias': days,
            'estado': status,
          })
          .eq('id', routeId);
      
      print('Route updated successfully');
      
      // Mark as success
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      print('Error updating route: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar el recorrido: $e',
        isSuccess: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void reset() {
    state = EditRouteState.initial();
  }
}

final editRouteProvider = StateNotifierProvider<EditRouteNotifier, EditRouteState>((ref) {
  return EditRouteNotifier();
});