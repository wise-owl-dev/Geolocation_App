// lib/features/bus_stops/providers/nearby_stops_provider.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/models/bus_stop.dart';

class NearbyStopsState {
  final bool isLoading;
  final List<BusStop> allStops;
  final List<NearbyBusStop> nearbyStops;
  final String? error;
  final double searchRadius; // Radio de búsqueda en kilómetros
  final LatLng? userLocation;

  NearbyStopsState({
    this.isLoading = false,
    this.allStops = const [],
    this.nearbyStops = const [],
    this.error,
    this.searchRadius = 1.0, // Por defecto 1 km
    this.userLocation,
  });

  NearbyStopsState copyWith({
    bool? isLoading,
    List<BusStop>? allStops,
    List<NearbyBusStop>? nearbyStops,
    String? error,
    double? searchRadius,
    LatLng? userLocation,
  }) {
    return NearbyStopsState(
      isLoading: isLoading ?? this.isLoading,
      allStops: allStops ?? this.allStops,
      nearbyStops: nearbyStops ?? this.nearbyStops,
      error: error,
      searchRadius: searchRadius ?? this.searchRadius,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

// Clase para mantener la parada y su distancia desde el usuario
class NearbyBusStop {
  final BusStop busStop;
  final double distance; // Distancia en metros

  NearbyBusStop({
    required this.busStop,
    required this.distance,
  });
}

class NearbyStopsNotifier extends StateNotifier<NearbyStopsState> {
  final _supabase = Supabase.instance.client;

  NearbyStopsNotifier() : super(NearbyStopsState());

  // Cargar todas las paradas
  Future<void> loadAllStops() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _supabase
          .from('paradas')
          .select()
          .eq('estado', 'activo')
          .order('nombre');

      final List<BusStop> stops = [];
      for (var item in result) {
        stops.add(BusStop.fromJson(item));
      }

      state = state.copyWith(
        isLoading: false,
        allStops: stops,
      );

      // Si tenemos la ubicación del usuario, actualizar las paradas cercanas
      if (state.userLocation != null) {
        _updateNearbyStops();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar paradas: $e',
      );
    }
  }

  // Actualizar la ubicación del usuario y recalcular paradas cercanas
  void updateUserLocation(LatLng location) {
    state = state.copyWith(userLocation: location);
    _updateNearbyStops();
  }

  // Cambiar el radio de búsqueda
  void updateSearchRadius(double radius) {
    state = state.copyWith(searchRadius: radius);
    _updateNearbyStops();
  }

  // Actualizar la lista de paradas cercanas
  void _updateNearbyStops() {
    if (state.userLocation == null || state.allStops.isEmpty) return;

    final userLat = state.userLocation!.latitude;
    final userLng = state.userLocation!.longitude;
    final radiusInMeters = state.searchRadius * 1000; // Convertir km a metros

    final List<NearbyBusStop> nearbyStops = [];

    for (var stop in state.allStops) {
      final distance = _calculateDistance(
        userLat, userLng, stop.latitude, stop.longitude);
      
      if (distance <= radiusInMeters) {
        nearbyStops.add(NearbyBusStop(
          busStop: stop,
          distance: distance,
        ));
      }
    }

    // Ordenar por distancia
    nearbyStops.sort((a, b) => a.distance.compareTo(b.distance));

    state = state.copyWith(nearbyStops: nearbyStops);
  }

  // Calcular la distancia entre dos puntos usando la fórmula haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371000; // radio de la Tierra en metros
    
    // Convertir a radianes
    final double lat1Rad = lat1 * (pi / 180);
    final double lon1Rad = lon1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double lon2Rad = lon2 * (pi / 180);
    
    // Diferencias
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    
    // Fórmula haversine
    final double a = sin(dLat / 2) * sin(dLat / 2) +
                     cos(lat1Rad) * cos(lat2Rad) *
                     sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c; // distancia en metros
  }

  // Buscar rutas que pasan por una parada específica
  Future<List<String>> getRoutesThroughStop(String stopId) async {
    try {
      final result = await _supabase
          .from('recorrido_paradas')
          .select('recorridos(nombre)')
          .eq('parada_id', stopId);

      final List<String> routeNames = [];
      for (var item in result) {
        if (item['recorridos'] != null && item['recorridos']['nombre'] != null) {
          routeNames.add(item['recorridos']['nombre']);
        }
      }

      return routeNames;
    } catch (e) {
      print('Error obteniendo rutas para parada $stopId: $e');
      return [];
    }
  }
}

final nearbyStopsProvider = StateNotifierProvider<NearbyStopsNotifier, NearbyStopsState>((ref) {
  return NearbyStopsNotifier();
});