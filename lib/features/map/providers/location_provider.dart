// lib/features/map/providers/location_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/models/location.dart' as custom_location;

class LocationState {
  final LatLng? currentLocation;
  final bool isTracking;
  final String? error;
  final bool hasPermission;
  final bool isLoading;
  final List<custom_location.Location> locationHistory;
  final custom_location.Location? lastLocation;
  
  LocationState({
    this.currentLocation,
    this.isTracking = false,
    this.error,
    this.hasPermission = false,
    this.isLoading = false,
    this.locationHistory = const [],
    this.lastLocation,
  });

  LocationState copyWith({
    LatLng? currentLocation,
    bool? isTracking,
    String? error,
    bool? hasPermission,
    bool? isLoading,
    List<custom_location.Location>? locationHistory,
    custom_location.Location? lastLocation,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
      error: error,
      hasPermission: hasPermission ?? this.hasPermission,
      isLoading: isLoading ?? this.isLoading,
      locationHistory: locationHistory ?? this.locationHistory,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}

// Provider for location management
class LocationNotifier extends StateNotifier<LocationState> {
  final _supabase = Supabase.instance.client;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  String? _assignmentId;
  Timer? _periodicLocationUpdateTimer;

  LocationNotifier() : super(LocationState()) {
    _initLocationService();
  }

  // Initialize location service and check permissions
  Future<void> _initLocationService() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          state = state.copyWith(
            error: 'El servicio de ubicación está desactivado',
            isLoading: false,
          );
          return;
        }
      }

      // Check if permissions are granted
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          state = state.copyWith(
            error: 'Se requiere permiso de ubicación',
            isLoading: false,
          );
          return;
        }
      }

      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // Update every 10 seconds
        distanceFilter: 5, // Minimum distance (meters) before updates
      );

      // Get current location once
      await _updateCurrentLocation();
      
      // Set up periodic location updates even when not actively tracking
      _setupPeriodicLocationUpdates();

      state = state.copyWith(
        hasPermission: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al inicializar la ubicación: $e',
        isLoading: false,
      );
    }
  }
  
  // Setup periodic location updates
  void _setupPeriodicLocationUpdates() {
    // Cancel existing timer if any
    _periodicLocationUpdateTimer?.cancel();
    
    // Update location every 30 seconds
    _periodicLocationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateCurrentLocation();
    });
  }
  
  // Update current location without starting tracking
  Future<void> _updateCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        
        state = state.copyWith(currentLocation: currentLocation);
        print('Current location updated: ${currentLocation.latitude}, ${currentLocation.longitude}');
      }
    } catch (e) {
      print('Error updating current location: $e');
    }
  }
  
  // Force update current location and return it
  Future<LatLng?> getCurrentLocation() async {
    try {
      await _updateCurrentLocation();
      return state.currentLocation;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Start tracking location
  Future<void> startTracking(String assignmentId) async {
    if (state.isTracking) return;
    
    _assignmentId = assignmentId;
    
    try {
      state = state.copyWith(isTracking: true);
      
      // Start listening to location updates
      _locationSubscription = _location.onLocationChanged.listen((locationData) {
        _updateLocation(locationData);
      });
    } catch (e) {
      state = state.copyWith(
        error: 'Error al iniciar el seguimiento: $e',
        isTracking: false,
      );
    }
  }

  // Stop tracking location
  void stopTracking() {
    _locationSubscription?.cancel();
    _assignmentId = null;
    state = state.copyWith(isTracking: false);
  }

  // Update location with new data and save to database
  Future<void> _updateLocation(LocationData locationData) async {
    if (locationData.latitude == null || locationData.longitude == null || _assignmentId == null) {
      return;
    }

    final newLocation = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    try {
      // Guardar ubicación en la base de datos
      final result = await _supabase.from('ubicaciones').insert({
        'asignacion_id': _assignmentId,
        'latitud': newLocation.latitude,
        'longitud': newLocation.longitude,
        'velocidad': locationData.speed,
        'timestamp': DateTime.now().toIso8601String(),
        'parada_actual_id': await _findNearestStop(newLocation),
      }).select();

      if (result.isNotEmpty) {
        final savedLocation = custom_location.Location.fromJson(result[0]);
        
        // Actualizar estado con nueva ubicación
        state = state.copyWith(
          currentLocation: newLocation,
          lastLocation: savedLocation,
          locationHistory: [...state.locationHistory, savedLocation],
        );
      }
    } catch (e) {
      print('Error saving location: $e');
      // Actualizar estado con nueva ubicación pero sin guardar en el historial
      state = state.copyWith(
        currentLocation: newLocation,
      );
    }
  }

  // Encontrar la parada más cercana
Future<String?> _findNearestStop(LatLng location) async {
  try {
    // Obtener todas las paradas de la ruta actual
    // Esto requiere conocer el routeId de la asignación actual
    // Por simplicidad, buscar la parada más cercana en un radio de 100m
    
    final result = await _supabase
        .from('paradas')
        .select()
        .eq('estado', 'activo');
    
    double minDistance = double.infinity;
    String? nearestStopId;
    
    for (var stop in result) {
      final stopLat = stop['latitud'] as double;
      final stopLng = stop['longitud'] as double;
      
      final distance = _calculateDistance(
        location.latitude,
        location.longitude,
        stopLat,
        stopLng,
      );
      
      // Si está a menos de 100 metros (0.1 km)
      if (distance < 0.1 && distance < minDistance) {
        minDistance = distance;
        nearestStopId = stop['id'] as String;
      }
    }
    
    return nearestStopId;
  } catch (e) {
    print('Error finding nearest stop: $e');
    return null;
  }
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371;
  
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

  // Get location history for a specific assignment
  Future<void> fetchLocationHistory(String assignmentId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _supabase
          .from('ubicaciones')
          .select()
          .eq('asignacion_id', assignmentId)
          .order('timestamp', ascending: true);

      final List<custom_location.Location> locations = [];
      for (var item in result) {
        locations.add(custom_location.Location.fromJson(item));
      }

      state = state.copyWith(
        locationHistory: locations,
        lastLocation: locations.isNotEmpty ? locations.last : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al obtener el historial de ubicaciones: $e',
        isLoading: false,
      );
    }
  }

  // Get real-time location updates for a specific assignment
  StreamSubscription<List<Map<String, dynamic>>> subscribeToLocationUpdates(
    String assignmentId,
    Function(custom_location.Location) onLocationUpdate,
  ) {
    return _supabase
        .from('ubicaciones')
        .stream(primaryKey: ['id'])
        .eq('asignacion_id', assignmentId)
        .order('timestamp')
        .listen((data) {
          if (data.isNotEmpty) {
            final latestLocation = custom_location.Location.fromJson(data.last);
            onLocationUpdate(latestLocation);
          }
        });
  }

  // Update current location manually (useful for testing)
  void updateCurrentLocation(double latitude, double longitude) {
    state = state.copyWith(
      currentLocation: LatLng(latitude, longitude),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _periodicLocationUpdateTimer?.cancel();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});