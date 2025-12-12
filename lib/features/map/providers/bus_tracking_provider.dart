// lib/features/map/providers/bus_tracking_provider.dart
// lib/features/map/providers/bus_tracking_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/models/location.dart' as custom_location;
import 'map_provider.dart';

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});

class BusTrackingState {
  final bool isLoading;
  final Map<String, Assignment> activeAssignments;
  final Map<String, Bus> activeBuses;
  final Map<String, custom_location.Location> lastLocations;
  final String? error;
  final String? selectedBusId;
  final Assignment? selectedAssignment;
  final List<LatLng> busPath;

  BusTrackingState({
    this.isLoading = false,
    this.activeAssignments = const {},
    this.activeBuses = const {},
    this.lastLocations = const {},
    this.error,
    this.selectedBusId,
    this.selectedAssignment,
    this.busPath = const [],
  });

  BusTrackingState copyWith({
    bool? isLoading,
    Map<String, Assignment>? activeAssignments,
    Map<String, Bus>? activeBuses,
    Map<String, custom_location.Location>? lastLocations,
    String? error,
    String? selectedBusId,
    Assignment? selectedAssignment,
    List<LatLng>? busPath,
  }) {
    return BusTrackingState(
      isLoading: isLoading ?? this.isLoading,
      activeAssignments: activeAssignments ?? this.activeAssignments,
      activeBuses: activeBuses ?? this.activeBuses,
      lastLocations: lastLocations ?? this.lastLocations,
      error: error,
      selectedBusId: selectedBusId ?? this.selectedBusId,
      selectedAssignment: selectedAssignment ?? this.selectedAssignment,
      busPath: busPath ?? this.busPath,
    );
  }
}

class BusTrackingNotifier extends StateNotifier<BusTrackingState> {
  final _supabase = Supabase.instance.client;
  final Ref _ref;
  StreamSubscription<List<Map<String, dynamic>>>? _locationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _assignmentSubscription;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _individualTracking = {};
  Timer? _refreshTimer;

  BusTrackingNotifier(this._ref) : super(BusTrackingState()) {
    // Refresh active buses every minute to get any new assignments
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshActiveBuses();
    });
    
    // Initial load
    refreshActiveBuses();
  }

  // Nuevo método para suscribirse a actualizaciones de ubicación individuales
  StreamSubscription<dynamic> subscribeToLocationUpdates(
    String assignmentId,
    void Function(custom_location.Location) onLocationUpdate,
  ) {
    // Cancelar suscripción existente si ya hay una para esta asignación
    _individualTracking[assignmentId]?.cancel();
    
    // Crear la suscripción
    final subscription = _supabase
        .from('ubicaciones')
        .stream(primaryKey: ['id'])
        .eq('asignacion_id', assignmentId)
        .order('timestamp', ascending: false)
        .limit(1)
        .listen((data) {
          if (data.isNotEmpty) {
            final location = custom_location.Location.fromJson(data[0]);
            // Llamar al callback con la ubicación actualizada
            onLocationUpdate(location);
          }
        });
    
    // Guardar la suscripción
    _individualTracking[assignmentId] = subscription;
    
    // También obtener la última ubicación conocida inmediatamente
    _fetchLastLocation(assignmentId).then((location) {
      if (location != null) {
        onLocationUpdate(location);
      }
    });
    
    return subscription;
  }

  // Load buses that are currently active (have an active assignment)
  Future<void> refreshActiveBuses() async {
  if (state.isLoading) return;
  
  state = state.copyWith(isLoading: true);
  
  try {
    // Obtener todas las asignaciones activas
    final assignmentResult = await _supabase
        .from('asignaciones')
        .select('''
          *,
          autobuses:autobus_id (*),
          usuarios:operador_id (nombre, apellido_paterno),
          recorridos:recorrido_id (nombre)
        ''')
        .or('estado.eq.programada,estado.eq.en_curso')  // Solo programadas o en curso
        .lte('fecha_inicio', DateTime.now().toIso8601String())
        .or('fecha_fin.is.null,fecha_fin.gte.${DateTime.now().toIso8601String()}');
    
    print('Found ${assignmentResult.length} active assignments');
    
    final Map<String, Assignment> assignments = {};
    final Map<String, Bus> buses = {};
    
    for (var item in assignmentResult) {
      try {
        // Extraer los datos relacionados
        final busData = item['autobuses'];
        final operatorData = item['usuarios'];
        final routeData = item['recorridos'];
        
        if (busData != null) {
          final bus = Bus.fromJson(busData);
          
          // Crear asignación con datos relacionados
          final assignment = Assignment.fromJson(
            item,
            operatorName: operatorData != null 
                ? '${operatorData['nombre']} ${operatorData['apellido_paterno']}' 
                : null,
            busNumber: bus.busNumber,
            routeName: routeData != null ? routeData['nombre'] : null,
          );
          
          assignments[assignment.id] = assignment;
          buses[bus.id] = bus;
          
          // Solo comenzar a rastrear autobuses en estado "en_curso"
          if (assignment.status == AssignmentStatus.en_curso) {
            print('Tracking bus ${bus.busNumber} for assignment ${assignment.id} in status: ${assignment.status.name}');
            _trackBusLocation(assignment.id, bus.id, bus.busNumber);
          }
        }
      } catch (e) {
        print('Error processing assignment: $e');
      }
    }
    
    state = state.copyWith(
      activeAssignments: assignments,
      activeBuses: buses,
      isLoading: false,
    );
    
    // Si tenemos un autobús seleccionado, asegurarnos de que aún tengamos sus datos
    if (state.selectedBusId != null && !buses.containsKey(state.selectedBusId)) {
      // El autobús ya no está activo, limpiar selección
      clearSelectedBus();
    }
  } catch (e) {
    print('Error loading active buses: $e');
    state = state.copyWith(
      error: 'Error loading active buses: $e',
      isLoading: false,
    );
  }
}
  // Start tracking location updates for a specific bus
 void _trackBusLocation(String assignmentId, String busId, String busNumber) {
  print('Starting to track bus location for assignment: $assignmentId, bus: $busId');
  // Primero intentar obtener la última ubicación conocida
  _fetchLastLocation(assignmentId).then((lastLocation) {
    if (lastLocation != null) {
      print('Found last location for bus $busNumber: ${lastLocation.latitude}, ${lastLocation.longitude}');
      _updateBusMarker(lastLocation, busId, busNumber, assignmentId);
    } else {
      print('No previous location found for bus $busNumber');
    }
    
    // Ahora configurar actualizaciones en tiempo real
    try {
      print('Setting up real-time location updates for bus $busNumber');
      final subscription = _supabase
          .from('ubicaciones')
          .stream(primaryKey: ['id'])
          .eq('asignacion_id', assignmentId)
          .order('timestamp', ascending: false)
          .limit(1)
          .listen(
            (data) {
              if (data.isNotEmpty) {
                print('Received real-time location update for bus $busNumber');
                final location = custom_location.Location.fromJson(data[0]);
                _updateBusMarker(location, busId, busNumber, assignmentId);
              }
            },
            onError: (error) {
              print('Error subscribing to bus location updates: $error');
            },
          );
      
      // Guardar la suscripción para cancelarla luego si es necesario
      if (_individualTracking.containsKey(assignmentId)) {
        print('Cancelling previous subscription for bus $busNumber');
        _individualTracking[assignmentId]?.cancel();
      }
      _individualTracking[assignmentId] = subscription;
    } catch (e) {
      print('Error setting up location subscription: $e');
    }
  }).catchError((error) {
    print('Error fetching last location: $error');
  });
}

  // Get the last known location for a bus
  Future<custom_location.Location?> _fetchLastLocation(String assignmentId) async {
    try {
      final result = await _supabase
          .from('ubicaciones')
          .select()
          .eq('asignacion_id', assignmentId)
          .order('timestamp', ascending: false)
          .limit(1);
      
      if (result.isNotEmpty) {
        final location = custom_location.Location.fromJson(result[0]);
        
        // Update state with this location
        final lastLocations = {...state.lastLocations};
        lastLocations[assignmentId] = location;
        state = state.copyWith(lastLocations: lastLocations);
        
        return location;
      }
    } catch (e) {
      print('Error fetching last location: $e');
    }
    return null;
  }

  // Update the bus marker on the map
  void _updateBusMarker(
    custom_location.Location location,
    String busId,
    String busNumber,
    String assignmentId,
  ) {
    // Update our state with the latest location
    final lastLocations = {...state.lastLocations};
    lastLocations[assignmentId] = location;
    state = state.copyWith(lastLocations: lastLocations);
    
    // Get the assignment to include route info in marker
    final assignment = state.activeAssignments[assignmentId];
    
    // Get bus position as LatLng
    final position = LatLng(location.latitude, location.longitude);
    
    // Calculate rotation if possible by comparing with previous position
    double? rotation;
    
    // Update the marker on the map
    _ref.read(mapProvider.notifier).addBusMarker(
      id: 'bus_$busId',
      position: position,
      title: 'Unidad $busNumber',
      snippet: assignment?.routeName != null 
          ? 'Ruta: ${assignment!.routeName}' 
          : null,
      rotation: rotation ?? 0.0,
      speed: location.speed ?? 0.0,
      busId: busId,
      routeId: assignment?.routeId,
      assignmentId: assignmentId,
    );
    
    // If this is the selected bus, update its path
    if (state.selectedBusId == busId) {
      _updateSelectedBusPath(assignmentId);
    }
  }

  // Select a bus to track in detail
  Future<void> selectBus(String busId) async {
    if (!state.activeBuses.containsKey(busId)) {
      return;
    }
    
    state = state.copyWith(
      selectedBusId: busId,
      isLoading: true,
    );
    
    try {
      // Find the assignment for this bus
      final assignment = state.activeAssignments.values.firstWhere(
        (a) => a.busId == busId,
        orElse: () => throw Exception('No active assignment found for this bus'),
      );
      
      state = state.copyWith(
        selectedAssignment: assignment,
      );
      
      // Fetch location history for this assignment
      await _updateSelectedBusPath(assignment.id);
      
      // Focus the map on this bus
      final lastLocation = state.lastLocations[assignment.id];
      if (lastLocation != null) {
        _ref.read(mapProvider.notifier).moveCamera(
          LatLng(lastLocation.latitude, lastLocation.longitude),
          zoom: 16.0,
        );
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Error selecting bus: $e',
        isLoading: false,
      );
    }
  }

  // Update the path for the selected bus
  Future<void> _updateSelectedBusPath(String assignmentId) async {
    try {
      // Get location history for this assignment
      final result = await _supabase
          .from('ubicaciones')
          .select()
          .eq('asignacion_id', assignmentId)
          .order('timestamp', ascending: true)
          .limit(100); // Limit to last 100 points to avoid performance issues
      
      final List<LatLng> path = [];
      
      for (var item in result) {
        final location = custom_location.Location.fromJson(item);
        path.add(LatLng(location.latitude, location.longitude));
      }
      
      state = state.copyWith(busPath: path);
      
      // Update the polyline on the map
      if (path.length > 1) {
        final mapNotifier = _ref.read(mapProvider.notifier);
        
        // Add polyline for bus path
        final polylines = <String, Polyline>{};
        polylines['bus_path'] = Polyline(
          polylineId: const PolylineId('bus_path'),
          points: path,
          color: Colors.red,
          width: 5,
        );
        
        // Update map state with the polyline
        _ref.read(mapProvider.notifier).updatePolyline('bus_path', polylines['bus_path']!);
      }
    } catch (e) {
      print('Error updating bus path: $e');
    }
  }

  // Clear selected bus
  void clearSelectedBus() {
    state = state.copyWith(
      selectedBusId: null,
      selectedAssignment: null,
      busPath: [],
    );
    
    // Clear the polyline from the map
    _ref.read(mapProvider.notifier).removePolyline('bus_path');
  }
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _assignmentSubscription?.cancel();
    _refreshTimer?.cancel();
    
    // Cancelar todas las suscripciones individuales
    for (var subscription in _individualTracking.values) {
      subscription.cancel();
    }
    _individualTracking.clear();
    
    super.dispose();
  }

  // Calcular tiempo estimado de llegada a una parada
  Future<Duration?> calculateEstimatedArrival(
    String assignmentId,
    String busStopId,
  ) async {
    try {
      // Obtener la última ubicación del autobús
      final lastLocation = state.lastLocations[assignmentId];
      if (lastLocation == null || lastLocation.speed == null || lastLocation.speed == 0) {
        return null; // No se puede calcular sin ubicación o velocidad
      }

      // Obtener las coordenadas de la parada
      final stopResult = await _supabase
          .from('paradas')
          .select('latitud, longitud')
          .eq('id', busStopId)
          .single();

      final stopLat = stopResult['latitud'] as double;
      final stopLng = stopResult['longitud'] as double;

      // Calcular distancia en kilómetros usando la fórmula de Haversine
      final distance = _calculateDistance(
        lastLocation.latitude,
        lastLocation.longitude,
        stopLat,
        stopLng,
      );

      // Calcular tiempo en minutos (distancia / velocidad * 60)
      // Añadir un factor de corrección para tráfico (1.3 = 30% más tiempo)
      final speedKmh = lastLocation.speed!;
      final timeInMinutes = (distance / speedKmh) * 60 * 1.3;

      return Duration(minutes: timeInMinutes.round());
    } catch (e) {
      print('Error calculating estimated arrival: $e');
      return null;
    }
  }

  // Calcular distancia entre dos puntos usando la fórmula de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radio de la Tierra en kilómetros
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}

// Mantén este provider para evitar duplicados
final busTrackingProvider = StateNotifierProvider<BusTrackingNotifier, BusTrackingState>((ref) {
  return BusTrackingNotifier(ref);
});