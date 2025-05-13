// lib/features/map/providers/location_provider.dart
import 'dart:async';
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
      final locationData = await _location.getLocation();
      final currentLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      state = state.copyWith(
        currentLocation: currentLocation,
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
      // Save location to database
      final result = await _supabase.from('ubicaciones').insert({
        'asignacion_id': _assignmentId,
        'latitud': newLocation.latitude,
        'longitud': newLocation.longitude,
        'velocidad': locationData.speed,
        'timestamp': DateTime.now().toIso8601String(),
      }).select();

      if (result.isNotEmpty) {
        final savedLocation = custom_location.Location.fromJson(result[0]);
        
        // Update state with new location
        state = state.copyWith(
          currentLocation: newLocation,
          lastLocation: savedLocation,
          locationHistory: [...state.locationHistory, savedLocation],
        );
      }
    } catch (e) {
      print('Error saving location: $e');
      // Update state with new location but don't save to history
      state = state.copyWith(
        currentLocation: newLocation,
      );
    }
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
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});