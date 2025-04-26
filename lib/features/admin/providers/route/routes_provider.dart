import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/route.dart' as app_route;

class RoutesState {
  final bool isLoading;
  final List<app_route.Route> routes;
  final String? error;

  RoutesState({
    required this.isLoading,
    required this.routes,
    this.error,
  });

  // Initial state
  factory RoutesState.initial() => RoutesState(
    isLoading: false,
    routes: [],
    error: null,
  );

  // CopyWith method for immutability
  RoutesState copyWith({
    bool? isLoading,
    List<app_route.Route>? routes,
    String? error,
  }) {
    return RoutesState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      error: error,
    );
  }
}

class RoutesNotifier extends StateNotifier<RoutesState> {
  final _supabase = Supabase.instance.client;

  RoutesNotifier() : super(RoutesState.initial());

  // Method to load all routes
  Future<void> loadRoutes() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Query all routes
      final result = await _supabase
          .from('recorridos')
          .select()
          .order('nombre', ascending: true);
      
      print('Query result: $result');
      
      if (result.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          routes: [],
        );
        return;
      }
      
      // Transform data into Route objects
      final List<app_route.Route> routes = [];
      
      for (var routeData in result) {
        try {
          print('Processing route: $routeData');
          final route = app_route.Route.fromJson(routeData);
          routes.add(route);
          print('Route added successfully');
        } catch (e) {
          print('Error processing route: $e');
          // Continue with the next one
        }
      }
      
      print('Total routes processed: ${routes.length}');
      
      state = state.copyWith(
        isLoading: false,
        routes: routes,
      );
    } catch (e) {
      print('Error loading routes: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar recorridos: $e',
      );
    }
  }
  
  // Method to delete a route
  Future<void> deleteRoute(String routeId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('Deleting route with ID: $routeId');
      
      // Delete from 'recorridos' table
      await _supabase
          .from('recorridos')
          .delete()
          .eq('id', routeId);
      
      print('Route deleted successfully');
      
      // Update local state
      final updatedRoutes = state.routes.where((route) => route.id != routeId).toList();
      
      state = state.copyWith(
        isLoading: false,
        routes: updatedRoutes,
      );
    } catch (e) {
      print('Error deleting route: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar el recorrido: $e',
      );
    }
  }

  // Method to refresh the list after adding a new route
  void refreshAfterAdd() {
    loadRoutes();
  }
}

final routesProvider = StateNotifierProvider<RoutesNotifier, RoutesState>((ref) {
  return RoutesNotifier();
});