// lib/features/routes/providers/routes_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/route.dart' as app_route;

class RoutesState {
  final bool isLoading;
  final List<app_route.Route> routes;
  final app_route.Route? selectedRoute;
  final String? error;

  RoutesState({
    this.isLoading = false,
    this.routes = const [],
    this.selectedRoute,
    this.error,
  });

  RoutesState copyWith({
    bool? isLoading,
    List<app_route.Route>? routes,
    app_route.Route? selectedRoute,
    String? error,
  }) {
    return RoutesState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      error: error,
    );
  }
}

class RoutesNotifier extends StateNotifier<RoutesState> {
  final _supabase = Supabase.instance.client;

  RoutesNotifier() : super(RoutesState());

  // Cargar todas las rutas
  Future<void> loadRoutes() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _supabase
          .from('recorridos')
          .select()
          .eq('estado', 'activo')
          .order('nombre');

      final List<app_route.Route> routes = [];
      for (var item in result) {
        routes.add(app_route.Route.fromJson(item));
      }

      state = state.copyWith(
        isLoading: false,
        routes: routes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar rutas: $e',
      );
    }
  }

  // Seleccionar una ruta específica y cargar sus detalles
  Future<void> selectRoute(String routeId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Buscar primero en las rutas ya cargadas
      var selectedRoute = state.routes.firstWhere(
        (route) => route.id == routeId,
        orElse: () => throw Exception('Ruta no encontrada'),
      );

      // Cargar información adicional de la ruta (paradas)
      final stopsResult = await _supabase
          .from('recorrido_paradas')
          .select('*, paradas(*)')
          .eq('recorrido_id', routeId)
          .order('orden');

      // Aquí podrías procesar los datos de paradas si lo necesitas
      // Por ahora, solo establecemos la ruta seleccionada

      state = state.copyWith(
        isLoading: false,
        selectedRoute: selectedRoute,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar detalles de ruta: $e',
      );
    }
  }

  // Limpiar la selección actual
  void clearSelectedRoute() {
    state = state.copyWith(selectedRoute: null);
  }

  // Buscar rutas por nombre
  Future<void> searchRoutes(String query) async {
    if (query.isEmpty) {
      return loadRoutes();
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _supabase
          .from('recorridos')
          .select()
          .ilike('nombre', '%$query%')
          .eq('estado', 'activo')
          .order('nombre');

      final List<app_route.Route> routes = [];
      for (var item in result) {
        routes.add(app_route.Route.fromJson(item));
      }

      state = state.copyWith(
        isLoading: false,
        routes: routes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar rutas: $e',
      );
    }
  }
}

final routesProvider = StateNotifierProvider<RoutesNotifier, RoutesState>((ref) {
  return RoutesNotifier();
});