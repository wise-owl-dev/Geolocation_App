// lib/features/admin/providers/route_stop/route_stops_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';

class RouteStopsState {
  final bool isLoading;
  final List<RouteStop> routeStops;
  final Map<String, BusStop> busStops; // Para almacenar los detalles de cada parada
  final String? error;

  RouteStopsState({
    required this.isLoading,
    required this.routeStops,
    required this.busStops,
    this.error,
  });

  factory RouteStopsState.initial() => RouteStopsState(
    isLoading: false,
    routeStops: [],
    busStops: {},
    error: null,
  );

  RouteStopsState copyWith({
    bool? isLoading,
    List<RouteStop>? routeStops,
    Map<String, BusStop>? busStops,
    String? error,
  }) {
    return RouteStopsState(
      isLoading: isLoading ?? this.isLoading,
      routeStops: routeStops ?? this.routeStops,
      busStops: busStops ?? this.busStops,
      error: error,
    );
  }
}

class RouteStopsNotifier extends StateNotifier<RouteStopsState> {
  final _supabase = Supabase.instance.client;

  RouteStopsNotifier() : super(RouteStopsState.initial());

  // Cargar las paradas de un recorrido específico
  Future<void> loadRouteStops(String routeId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Obtener la relación recorrido-paradas
      final result = await _supabase
          .from('recorrido_paradas')
          .select()
          .eq('recorrido_id', routeId)
          .order('orden');
      
      // Transformar datos en objetos RouteStop
      final List<RouteStop> routeStops = [];
      for (var data in result) {
        routeStops.add(RouteStop.fromJson(data));
      }
      
      // Obtener detalles de las paradas
      Map<String, BusStop> busStops = {};
      for (var routeStop in routeStops) {
        final stopData = await _supabase
            .from('paradas')
            .select()
            .eq('id', routeStop.stopId)
            .single();
        
        busStops[routeStop.stopId] = BusStop.fromJson(stopData);
      }
      
      state = state.copyWith(
        isLoading: false,
        routeStops: routeStops,
        busStops: busStops,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar las paradas del recorrido: $e',
      );
    }
  }

  // Añadir una parada a un recorrido
  Future<void> addStopToRoute({
    required String routeId,
    required String stopId,
    required int order,
    int? estimatedTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _supabase
          .from('recorrido_paradas')
          .insert({
            'recorrido_id': routeId,
            'parada_id': stopId,
            'orden': order,
            'tiempo_estimado': estimatedTime,
          })
          .select();
      
      // Obtener los datos de la parada
      final stopData = await _supabase
          .from('paradas')
          .select()
          .eq('id', stopId)
          .single();
      
      // Actualizar el estado
      final newRouteStop = RouteStop.fromJson(result[0]);
      final newBusStop = BusStop.fromJson(stopData);
      
      state = state.copyWith(
        isLoading: false,
        routeStops: [...state.routeStops, newRouteStop],
        busStops: {...state.busStops, stopId: newBusStop},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al añadir la parada al recorrido: $e',
      );
    }
  }

  Future<List<Route>> getAvailableRoutes() async {
  try {
    final result = await _supabase
        .from('recorridos')
        .select()
        .order('nombre', ascending: true);
    
    List<Route> routes = [];
    for (var routeData in result) {
      routes.add(Route.fromJson(routeData));
    }
    
    return routes;
  } catch (e) {
    print('Error al cargar recorridos: $e');
    return [];
  }
}

  // Eliminar una parada de un recorrido
  Future<void> removeStopFromRoute(String routeStopId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _supabase
          .from('recorrido_paradas')
          .delete()
          .eq('id', routeStopId);
      
      // Actualizar el estado
      final updatedRouteStops = state.routeStops
          .where((routeStop) => routeStop.id != routeStopId)
          .toList();
      
      state = state.copyWith(
        isLoading: false,
        routeStops: updatedRouteStops,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar la parada del recorrido: $e',
      );
    }
  }

  // Actualizar el orden de una parada en un recorrido
  Future<void> updateStopOrder({
    required String routeStopId,
    required int newOrder,
    int? estimatedTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _supabase
          .from('recorrido_paradas')
          .update({
            'orden': newOrder,
            if (estimatedTime != null) 'tiempo_estimado': estimatedTime,
          })
          .eq('id', routeStopId);
      
      // Actualizar el estado
      final index = state.routeStops.indexWhere((routeStop) => routeStop.id == routeStopId);
      if (index != -1) {
        final updatedRouteStop = RouteStop(
          id: state.routeStops[index].id,
          routeId: state.routeStops[index].routeId,
          stopId: state.routeStops[index].stopId,
          order: newOrder,
          estimatedTime: estimatedTime ?? state.routeStops[index].estimatedTime,
        );
        
        final updatedRouteStops = [...state.routeStops];
        updatedRouteStops[index] = updatedRouteStop;
        
        state = state.copyWith(
          isLoading: false,
          routeStops: updatedRouteStops,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar el orden de la parada: $e',
      );
    }
  }

  // Obtener el siguiente orden disponible
  int getNextAvailableOrder() {
    if (state.routeStops.isEmpty) return 1;
    return state.routeStops.map((rs) => rs.order).reduce((a, b) => a > b ? a : b) + 1;
  }
}

final routeStopsProvider = StateNotifierProvider<RouteStopsNotifier, RouteStopsState>((ref) {
  return RouteStopsNotifier();
});