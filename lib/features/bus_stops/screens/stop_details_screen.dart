import 'dart:math';// lib/features/bus_stops/screens/stop_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus_stop.dart';
import '../../../shared/models/route.dart' as app_route;
import '../../map/providers/location_provider.dart';
import '../providers/nearby_stops_provider.dart';

class StopDetailsScreen extends ConsumerStatefulWidget {
  final String stopId;
  
  const StopDetailsScreen({
    super.key,
    required this.stopId,
  });

  @override
  ConsumerState<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends ConsumerState<StopDetailsScreen> {
  BusStop? _stop;
  List<app_route.Route> _routes = [];
  bool _isLoading = true;
  String? _error;
  bool _showMap = true;
  double? _distanceToUser;
  
  @override
  void initState() {
    super.initState();
    _loadStopDetails();
  }
  
  Future<void> _loadStopDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final supabase = Supabase.instance.client;
      
      // Cargar información de la parada
      final stopResult = await supabase
          .from('paradas')
          .select()
          .eq('id', widget.stopId)
          .single();
      
      final stop = BusStop.fromJson(stopResult);
      
      // Cargar rutas que pasan por esta parada
      final routesResult = await supabase
          .from('recorrido_paradas')
          .select('recorrido_id, recorridos(*)')
          .eq('parada_id', widget.stopId);
      
      final List<app_route.Route> routes = [];
      for (var item in routesResult) {
        if (item['recorridos'] != null) {
          routes.add(app_route.Route.fromJson(item['recorridos']));
        }
      }
      
      // Calcular distancia si tenemos ubicación del usuario
      final locationState = ref.read(locationProvider);
      double? distance;
      
      if (locationState.currentLocation != null) {
        distance = _calculateDistance(
          locationState.currentLocation!.latitude,
          locationState.currentLocation!.longitude,
          stop.latitude,
          stop.longitude,
        );
      }
      
      setState(() {
        _stop = stop;
        _routes = routes;
        _distanceToUser = distance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar detalles de la parada: $e';
        _isLoading = false;
      });
    }
  }
  
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

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    
    // Si la ubicación del usuario cambia, actualizar la distancia
    if (locationState.currentLocation != null && _stop != null) {
      _distanceToUser = _calculateDistance(
        locationState.currentLocation!.latitude,
        locationState.currentLocation!.longitude,
        _stop!.latitude,
        _stop!.longitude,
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_stop?.name ?? 'Detalles de Parada'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'Ver rutas' : 'Ver mapa',
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorMessage()
              : Column(
                  children: [
                    // Información de la parada
                    _buildStopInfoCard(),
                    
                    // Mapa o lista de rutas
                    Expanded(
                      child: _showMap
                          ? _buildStopMap()
                          : _buildRoutesList(),
                    ),
                  ],
                ),
      floatingActionButton: _stop != null && locationState.currentLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                _launchMapsApp();
              },
              icon: const Icon(Icons.directions),
              label: const Text('Cómo llegar'),
            )
          : null,
    );
  }
  
  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar parada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStopDetails,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStopInfoCard() {
    if (_stop == null) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 24,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stop!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stop!.address ?? 'Dirección no disponible',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_distanceToUser != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191970),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDistance(_distanceToUser!),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191970),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(
                  Icons.route,
                  'Rutas',
                  '${_routes.length} rutas',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.access_time,
                  'Actualización',
                  'Hace 5 minutos', // Esto debería venir de la BD real
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStopMap() {
    if (_stop == null) return const SizedBox.shrink();
    
    // Crear marcadores
    final markers = <Marker>{
      Marker(
        markerId: MarkerId('stop_${_stop!.id}'),
        position: LatLng(_stop!.latitude, _stop!.longitude),
        infoWindow: InfoWindow(
          title: _stop!.name,
          snippet: _stop!.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
    
    // Añadir marcador de ubicación del usuario si está disponible
    final locationState = ref.read(locationProvider);
    if (locationState.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: locationState.currentLocation!,
          infoWindow: const InfoWindow(
            title: 'Tu ubicación',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_stop!.latitude, _stop!.longitude),
        zoom: 15,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
    );
  }
  
  Widget _buildRoutesList() {
    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay rutas que pasen por esta parada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final route = _routes[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF191970),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_bus,
                color: const Color.fromARGB(255, 255, 255, 255),
                size: 28,
              ),
            ),
            title: Text(
              route.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Horario: ${route.startTime} - ${route.endTime}',
                ),
                Text(
                  'Días: ${_formatDays(route.days)}',
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar a detalles de ruta
              context.push('/user/route-details/${route.id}');
            },
          ),
        );
      },
    );
  }
  
  void _launchMapsApp() {
    if (_stop == null) return;
    
    // Aquí se implementaría la apertura de la app de mapas nativa
    // con la ubicación de la parada. Por simplicidad, solo mostraremos
    // un SnackBar
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo navegación a: ${_stop!.name}'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    
    // La implementación real podría usar url_launcher para abrir Google Maps
    // final url = 'https://www.google.com/maps/dir/?api=1&destination=${_stop!.latitude},${_stop!.longitude}';
    // launch(url);
  }
  
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final kilometers = distanceInMeters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }
  
  String _formatDays(List<String> days) {
    if (days.isEmpty) return 'No disponible';
    
    // Ordenar días de la semana
    const dayOrder = {
      'lunes': 0, 'martes': 1, 'miércoles': 2, 'miercoles': 2,
      'jueves': 3, 'viernes': 4, 'sábado': 5, 'sabado': 5, 'domingo': 6
    };
    
    days.sort((a, b) {
      final aIndex = dayOrder[a.toLowerCase()] ?? 7;
      final bIndex = dayOrder[b.toLowerCase()] ?? 7;
      return aIndex.compareTo(bIndex);
    });
    
    // Capitalizar primera letra
    final formattedDays = days.map((day) {
      if (day.isEmpty) return day;
      return day[0].toUpperCase() + day.substring(1).toLowerCase();
    }).toList();
    
    // Si tiene todos los días de L-V, simplificar
    final weekdaySet = {'Lunes', 'Martes', 'Miércoles', 'Miercoles', 'Jueves', 'Viernes'};
    final daySet = formattedDays.toSet();
    
    if (weekdaySet.difference(daySet).isEmpty && daySet.containsAll(weekdaySet)) {
      // Si también tiene S-D, es toda la semana
      if (daySet.contains('Sábado') || daySet.contains('Sabado') && daySet.contains('Domingo')) {
        return 'Todos los días';
      }
      return 'Lunes a Viernes';
    }
    
    // De lo contrario, listar los días
    return formattedDays.join(', ');
  }
}