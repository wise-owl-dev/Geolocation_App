// lib/features/map/screens/bus_tracking_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/location_provider.dart';
import '../providers/bus_tracking_provider.dart';
import '../providers/map_provider.dart';
import '../../../shared/widgets/custom_filled_button.dart';
import '../../../shared/models/location.dart' as custom_location;

class BusTrackingScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const BusTrackingScreen({
    Key? key,
    required this.assignmentId,
  }) : super(key: key);

  @override
  ConsumerState<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends ConsumerState<BusTrackingScreen> {
  late GoogleMapController _mapController;
  StreamSubscription? _locationSubscription;
  bool _isTracking = false;
  bool _isLocating = false;
  LatLng? _lastPosition;
  
  @override
  void initState() {
    super.initState();
    // Start tracking the bus when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTracking();
    });
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _stopTracking();
    super.dispose();
  }
  
  void _startTracking() {
    final assignmentId = widget.assignmentId;
    
    // Set up real-time location updates
    _locationSubscription = ref
        .read(busTrackingProvider.notifier)
        .subscribeToLocationUpdates(
          assignmentId,
          _handleLocationUpdate,
        );
    
    setState(() {
      _isTracking = true;
    });
  }
  
  void _stopTracking() {
    _locationSubscription?.cancel();
    
    setState(() {
      _isTracking = false;
    });
  }
  
  void _handleLocationUpdate(custom_location.Location location) {
    // Update the bus marker on the map
    final busId = 'tracking_bus';
    final position = LatLng(location.latitude, location.longitude);
    
    // Calculate rotation if we have a previous position
    double? rotation;
    if (_lastPosition != null) {
      final dx = position.latitude - _lastPosition!.latitude;
      final dy = position.longitude - _lastPosition!.longitude;
      rotation = 57.3 * atan2(dy, dx); // Convert radians to degrees
    }
    
    // Update the marker
    ref.read(mapProvider.notifier).addBusMarker(
      id: busId,
      position: position,
      title: 'Autobús',
      rotation: rotation ?? 0.0,
      speed: location.speed,
    );
    
    // Update map view to follow bus
    if (_mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }
    
    // Store the position for next update
    _lastPosition = position;
  }

  // Nuevo método para ir a la ubicación del usuario
  Future<void> _goToMyLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      // Forzar actualización de la ubicación actual
      final currentLocation = await ref.read(locationProvider.notifier).getCurrentLocation();
      
      if (currentLocation != null) {
        // Usar el controlador directamente para mayor control
        await _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation,
              zoom: 16.0,
            ),
          ),
        );
        
        // Mostrar indicador de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación actual encontrada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Mostrar error si no se pudo obtener la ubicación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener tu ubicación actual. Verifica los permisos de ubicación.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error going to current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final locationState = ref.watch(locationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento en Tiempo Real'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Botón de ubicación mejorado
          IconButton(
            icon: _isLocating 
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  )
                : const Icon(Icons.my_location),
            tooltip: 'Ir a mi ubicación',
            onPressed: _isLocating ? null : _goToMyLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapState.initialPosition ?? const LatLng(19.4326, -99.1332),
              zoom: 15.0,
            ),
            markers: mapState.googleMapMarkers,
            polylines: mapState.googleMapPolylines,
            circles: mapState.circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              ref.read(mapProvider.notifier).onMapCreated(controller);
            },
            onCameraMove: (position) {
              ref.read(mapProvider.notifier).onCameraMove(position);
            },
          ),
          
          // Tracking controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildTrackingControls(),
          ),
          
          // Loading indicator
          if (mapState.isLoading)
            const Positioned(
              top: 16,
              right: 16,
              child: CircularProgressIndicator(),
            ),
            
          // Indicador de carga durante la localización
          if (_isLocating)
            Container(
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Buscando tu ubicación...'),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _isTracking ? Icons.location_on : Icons.location_off,
                  color: _isTracking ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isTracking 
                        ? 'Rastreando autobús en tiempo real' 
                        : 'Rastreo detenido',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isTracking ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomFilledButton(
                    text: _isTracking ? 'Detener Seguimiento' : 'Iniciar Seguimiento',
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    prefixIcon: Icon(
                      _isTracking ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isTracking) {
                        _stopTracking();
                      } else {
                        _startTracking();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}