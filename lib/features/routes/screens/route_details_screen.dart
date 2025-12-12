// lib/features/routes/screens/route_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus_stop.dart';
import '../../../shared/models/route.dart' as app_route;
import '../../../shared/widgets/loading_overlay.dart';
import 'dart:math';

class RouteDetailsScreen extends ConsumerStatefulWidget {
  final String routeId;
  
  const RouteDetailsScreen({
    super.key,
    required this.routeId,
  });

  @override
  ConsumerState<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends ConsumerState<RouteDetailsScreen> {
  bool _showMap = true;
  List<BusStop> _routeStops = [];
  Map<PolylineId, Polyline> _routePolylines = {};
  Map<MarkerId, Marker> _stopMarkers = {};
  bool _isLoadingStops = true;
  String? _error;
  
  // Variables para almacenar los datos de la ruta
  String? _routeName;
  String? _startTime;
  String? _endTime;
  List<String> _routeDays = [];
  
  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para evitar modificar el provider durante el ciclo de vida del widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRouteDetails();
    });
  }
  
  Future<void> _loadRouteDetails() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoadingStops = true;
        _error = null;
      });
      
      // Primero, cargar información básica de la ruta sin modificar el estado del provider
      final supabase = Supabase.instance.client;
      
      // Obtener la información de la ruta
      final routeResult = await supabase
          .from('recorridos')
          .select()
          .eq('id', widget.routeId)
          .single();
          
      // Imprimir los datos completos para depuración
      print("Datos de ruta recibidos: $routeResult");
      
      // Extraer los datos directamente del JSON - intentando diferentes nombres de campo posibles
      final String routeName = routeResult['nombre'] ?? 'Sin nombre';
      
      // Intentar diferentes nombres posibles para los campos de hora
      String? startTime;
      if (routeResult['hora_inicio'] != null) {
        startTime = routeResult['hora_inicio'];
      } else if (routeResult['horario_inicio'] != null) {
        startTime = routeResult['horario_inicio'];
      } else if (routeResult['inicio'] != null) {
        startTime = routeResult['inicio'];
      }
      
      String? endTime;
      if (routeResult['hora_fin'] != null) {
        endTime = routeResult['hora_fin'];
      } else if (routeResult['horario_fin'] != null) {
        endTime = routeResult['horario_fin'];
      } else if (routeResult['fin'] != null) {
        endTime = routeResult['fin'];
      }
      
      // Verificar los nombres de los campos disponibles en routeResult
      print("Nombres de campos disponibles: ${routeResult.keys.toList()}");
      print("Valor de hora_inicio: ${routeResult['hora_inicio']}");
      print("Valor de hora_fin: ${routeResult['hora_fin']}");
      
      final List<String> routeDays = routeResult['dias'] != null 
          ? List<String>.from(routeResult['dias']) 
          : [];
          
      // Guardar los datos de la ruta inmediatamente después de obtenerlos
      if (mounted) {
        setState(() {
          _routeName = routeName;
          _startTime = startTime;
          _endTime = endTime;
          _routeDays = routeDays;
        });
      }
      
      // Obtener paradas y coordenadas de ruta desde Supabase
      final stopsResult = await supabase
          .from('recorrido_paradas')
          .select('orden, paradas(*)')
          .eq('recorrido_id', widget.routeId)
          .order('orden');
      
      if (!mounted) return;
      
      // Procesar paradas
      List<BusStop> stops = [];
      List<LatLng> routePoints = [];
      Map<MarkerId, Marker> markers = {};
      
      for (var item in stopsResult) {
        if (item['paradas'] != null) {
          final stop = BusStop.fromJson(item['paradas']);
          stops.add(stop);
          
          // Añadir punto para el polyline
          routePoints.add(LatLng(stop.latitude, stop.longitude));
          
          // Crear marcador
          final markerId = MarkerId('stop_${stop.id}');
          final marker = Marker(
            markerId: markerId,
            position: LatLng(stop.latitude, stop.longitude),
            infoWindow: InfoWindow(
              title: '${item['orden']}. ${stop.name}',
              snippet: stop.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          );
          
          markers[markerId] = marker;
        }
      }
      
      // Crear polyline para la ruta
      final polylineId = PolylineId('route_${widget.routeId}');
      final polyline = Polyline(
        polylineId: polylineId,
        points: routePoints,
        color: const Color(0xFF191970),
        width: 5,
      );
      
      if (!mounted) return;
      
      setState(() {
        _routeStops = stops;
        _stopMarkers = markers;
        _routePolylines = {polylineId: polyline};
        _isLoadingStops = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Error al cargar detalles de la ruta: $e';
        _isLoadingStops = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routeName ?? 'Detalles de Ruta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'Ver lista de paradas' : 'Ver mapa',
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: _error != null
          ? _buildErrorMessage()
          : Column(
              children: [
                // Información de la ruta
                _buildRouteInfoCard(),
                
                // Mapa o lista de paradas
                Expanded(
                  child: _isLoadingStops && _routeStops.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _showMap
                          ? _buildRouteMap()
                          : _buildStopsList(),
                ),
              ],
            ),
    );
  }
  
  // Método para mostrar mensajes de error
  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar ruta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Error desconocido'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRouteDetails,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRouteInfoCard() {
    // Si estamos cargando y no tenemos el nombre de la ruta, mostrar loading
    if (_isLoadingStops && _routeName == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    // Si tenemos error o no hay datos, mostrar un mensaje
    if (_routeName == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 36),
              const SizedBox(height: 8),
              const Text(
                'Información de ruta no disponible',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Intenta recargar la página',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    
    // Si tenemos los datos, mostrar la tarjeta completa
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
                    color: const Color(0xFF191970),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    size: 24,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _routeName!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Horario: ${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem(
                  Icons.calendar_today,
                  'Días',
                  _formatDays(_routeDays),
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.location_on,
                  'Paradas',
                  '${_routeStops.length} paradas',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método para formatear la hora correctamente
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--';
    
    // Si el tiempo ya está en formato HH:MM, devolverlo directamente
    if (time.contains(':')) return time;
    
    // Si el tiempo está en otro formato, intentar interpretarlo
    try {
      // Si es solo la hora (por ejemplo, "7" o "14")
      if (time.length <= 2 && int.tryParse(time) != null) {
        final hour = int.parse(time);
        return '$hour:00';
      }
      
      // Si el tiempo está en formato de hora decimal (por ejemplo, "7.5" para las 7:30)
      if (time.contains('.')) {
        final parts = time.split('.');
        final hour = int.parse(parts[0]);
        final decimalPart = int.parse(parts[1]);
        final minutes = (decimalPart * 60 / 10).round(); // Convertir decimal a minutos
        return '$hour:${minutes.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      // Si hay algún error en la conversión, devolver el valor original
      return time;
    }
    
    return time;
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRouteMap() {
    if (_isLoadingStops) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_routeStops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay paradas definidas para esta ruta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // Calcular la posición inicial centrada en la ruta
    final bounds = _calculateBounds();
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _routeStops.isNotEmpty
            ? LatLng(_routeStops[0].latitude, _routeStops[0].longitude)
            : const LatLng(19.4326, -99.1332), // Fallback a CDMX
        zoom: 12,
      ),
      markers: Set<Marker>.of(_stopMarkers.values),
      polylines: Set<Polyline>.of(_routePolylines.values),
      onMapCreated: (controller) {
        if (bounds != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      },
    );
  }
  
  Widget _buildStopsList() {
    if (_isLoadingStops) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_routeStops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay paradas definidas para esta ruta',
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
      itemCount: _routeStops.length,
      separatorBuilder: (context, index) {
        // Si no es el último elemento, mostrar línea de conexión
        if (index < _routeStops.length - 1) {
          return _buildConnectionLine();
        }
        return const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        final stop = _routeStops[index];
        return _buildStopItem(stop, index + 1);
      },
    );
  }
  
  Widget _buildStopItem(BusStop stop, int order) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF191970),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              order.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          stop.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          stop.address ?? 'Dirección no disponible',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        onTap: () {
          // Navegar a detalles de parada
          context.push('/user/stop-details/${stop.id}');
        },
      ),
    );
  }
  
  Widget _buildConnectionLine() {
    return Row(
      children: [
        const SizedBox(width: 18),
        Container(
          width: 2,
          height: 30,
          color: const Color(0xFF191970),
        ),
      ],
    );
  }
  
  LatLngBounds? _calculateBounds() {
    if (_routeStops.isEmpty) return null;
    
    double minLat = _routeStops[0].latitude;
    double maxLat = _routeStops[0].latitude;
    double minLng = _routeStops[0].longitude;
    double maxLng = _routeStops[0].longitude;
    
    for (var stop in _routeStops) {
      minLat = min(minLat, stop.latitude);
      maxLat = max(maxLat, stop.latitude);
      minLng = min(minLng, stop.longitude);
      maxLng = max(maxLng, stop.longitude);
    }
    
    // Añadir un pequeño padding
    const padding = 0.01;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
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