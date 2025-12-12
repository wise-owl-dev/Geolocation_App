// lib/features/bus_stops/screens/nearby_stops_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/nearby_stops_provider.dart';
import '../widgets/bus_stop_card.dart';
import '../../map/providers/location_provider.dart';
import '../../../shared/widgets/loading_overlay.dart';

class NearbyStopsScreen extends ConsumerStatefulWidget {
  const NearbyStopsScreen({super.key});

  @override
  ConsumerState<NearbyStopsScreen> createState() => _NearbyStopsScreenState();
}

class _NearbyStopsScreenState extends ConsumerState<NearbyStopsScreen> {
  final List<double> _radiusOptions = [0.5, 1.0, 2.0, 5.0];
  double _selectedRadius = 1.0; // Por defecto 1 km
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    // Cargar paradas al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nearbyStopsProvider.notifier).loadAllStops();
      
      // Obtener la ubicación actual del usuario
      final locationState = ref.read(locationProvider);
      if (locationState.currentLocation != null) {
        ref.read(nearbyStopsProvider.notifier).updateUserLocation(
          locationState.currentLocation!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearbyStopsState = ref.watch(nearbyStopsProvider);
    final locationState = ref.watch(locationProvider);
    
    // Si la ubicación cambia, actualizar las paradas cercanas
    if (locationState.currentLocation != null && 
        nearbyStopsState.userLocation != locationState.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(nearbyStopsProvider.notifier).updateUserLocation(
          locationState.currentLocation!,
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paradas Cercanas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Botón para alternar entre mapa y lista
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'Ver lista' : 'Ver mapa',
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
          // Botón para obtener ubicación actual
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Mi ubicación',
            onPressed: () {
              final location = locationState.currentLocation;
              if (location != null) {
                ref.read(nearbyStopsProvider.notifier).updateUserLocation(location);
                
                if (_showMap) {
                  // Si estamos en el mapa, centrar en la ubicación del usuario
                  setState(() {
                    // La lógica para centrar el mapa se maneja en el widget del mapa
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo obtener tu ubicación actual'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Radio selector
          Column(
            children: [
              // Selector de radio
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.adjust,
                          color: const Color(0xFF191970),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Radio de búsqueda: $_selectedRadius km',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _radiusOptions.map((radius) {
                        final isSelected = radius == _selectedRadius;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRadius = radius;
                            });
                            ref.read(nearbyStopsProvider.notifier).updateSearchRadius(radius);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF191970)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF191970)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              '$radius km',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color.fromARGB(255, 255, 255, 255)
                                    : Colors.grey.shade700,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // Contenido principal (mapa o lista)
              Expanded(
                child: _showMap
                    ? _buildMap(nearbyStopsState, locationState)
                    : _buildStopsList(nearbyStopsState),
              ),
            ],
          ),
          
          // Indicador de carga
          if (nearbyStopsState.isLoading)
            const LoadingOverlay(),
          
          // Mensaje de ubicación no disponible
          if (locationState.currentLocation == null && !locationState.isLoading)
            _buildNoLocationMessage(),
        ],
      ),
    );
  }

  Widget _buildMap(NearbyStopsState nearbyStopsState, LocationState locationState) {
    if (locationState.currentLocation == null) {
      return const Center(
        child: Text('Esperando ubicación...'),
      );
    }
    
    // Crear marcadores para las paradas cercanas
    final Set<Marker> markers = {};
    
    // Marcador para la ubicación del usuario
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: locationState.currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Tu ubicación',
        ),
      ),
    );
    
    // Marcadores para paradas cercanas
    for (var nearbyStop in nearbyStopsState.nearbyStops) {
      markers.add(
        Marker(
          markerId: MarkerId('stop_${nearbyStop.busStop.id}'),
          position: LatLng(
            nearbyStop.busStop.latitude,
            nearbyStop.busStop.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: nearbyStop.busStop.name,
            snippet: 'A ${_formatDistance(nearbyStop.distance)} de distancia',
            onTap: () {
              // Navegar a detalles de la parada
              context.push('/user/stop-details/${nearbyStop.busStop.id}');
            },
          ),
        ),
      );
    }
    
    // Crear un círculo para representar el radio de búsqueda
    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('search_radius'),
        center: locationState.currentLocation!,
        radius: _selectedRadius * 1000, // Convertir km a metros
        fillColor: const Color(0xFF191970).withOpacity(0.1),
        strokeColor: const Color(0xFF191970).withOpacity(0.5),
        strokeWidth: 1,
      ),
    };
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: locationState.currentLocation!,
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      markers: markers,
      circles: circles,
      onMapCreated: (controller) {
        // Puedes guardar el controlador si necesitas manipular el mapa más tarde
      },
    );
  }

  Widget _buildStopsList(NearbyStopsState nearbyStopsState) {
    if (nearbyStopsState.isLoading && nearbyStopsState.nearbyStops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (nearbyStopsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar paradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(nearbyStopsState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(nearbyStopsProvider.notifier).loadAllStops(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (nearbyStopsState.nearbyStops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay paradas cercanas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba aumentando el radio de búsqueda',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: nearbyStopsState.nearbyStops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final nearbyStop = nearbyStopsState.nearbyStops[index];
        return BusStopCard(
          busStop: nearbyStop.busStop,
          distance: nearbyStop.distance,
          onTap: () {
            // Navegar a detalles de la parada
            context.push('/user/stop-details/${nearbyStop.busStop.id}');
          },
        );
      },
    );
  }

  Widget _buildNoLocationMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_off,
                color: Colors.orange.shade900,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se pudo obtener tu ubicación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Para ver las paradas cercanas, necesitamos acceder a tu ubicación. '
            'Activa los permisos de ubicación en la configuración de tu dispositivo.',
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Intentar obtener ubicación nuevamente
              // Esta debería ser una implementación más completa que solicite permisos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Intentando obtener ubicación...'),
                ),
              );
            },
            child: const Text('Permitir acceso a ubicación'),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final kilometers = distanceInMeters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }
}