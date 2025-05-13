// lib/features/map/screens/bus_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/models/assignment.dart';
import '../providers/map_provider.dart';
import '../providers/location_provider.dart';
import '../providers/bus_tracking_provider.dart';
import '../widgets/route_selector.dart';
import '../widgets/bus_info_panel.dart';
import '../../../shared/models/bus.dart';
import '../../../shared/models/location.dart' as custom_location;

class BusMapScreen extends ConsumerStatefulWidget {
  const BusMapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends ConsumerState<BusMapScreen> {
  @override
  void initState() {
    super.initState();
    // Start loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(busTrackingProvider.notifier).refreshActiveBuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final locationState = ref.watch(locationProvider);
    final busTrackingState = ref.watch(busTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Autobuses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (busTrackingState.selectedBusId != null)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Dejar de seguir este autobús',
              onPressed: () {
                ref.read(busTrackingProvider.notifier).clearSelectedBus();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar autobuses activos',
            onPressed: () {
              ref.read(busTrackingProvider.notifier).refreshActiveBuses();
            },
          ),
          if (locationState.currentLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Ir a mi ubicación',
              onPressed: () {
                if (locationState.currentLocation != null) {
                  ref.read(mapProvider.notifier).moveCamera(
                    locationState.currentLocation!,
                    zoom: 16.0,
                  );
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          _buildMap(mapState),
          
          // Route selector at the top
          if (busTrackingState.selectedBusId == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: RouteSelector(
                routes: mapState.routes,
                selectedRouteId: mapState.selectedRouteId,
                onRouteSelected: (routeId) {
                  ref.read(mapProvider.notifier).selectRoute(routeId);
                },
                onClearRoute: () {
                  ref.read(mapProvider.notifier).clearRoute();
                },
              ),
            ),
          
          // Active buses panel at the bottom
          if (busTrackingState.activeBuses.isNotEmpty && busTrackingState.selectedBusId == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActiveBusesPanel(busTrackingState),
            ),
          
          // Selected bus info panel
          if (busTrackingState.selectedBusId != null && 
              busTrackingState.selectedAssignment != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BusInfoPanel(
                assignment: busTrackingState.selectedAssignment!,
                bus: busTrackingState.activeBuses[busTrackingState.selectedBusId]!,
                lastLocation: busTrackingState.lastLocations[busTrackingState.selectedAssignment!.id],
                onClose: () {
                  ref.read(busTrackingProvider.notifier).clearSelectedBus();
                },
              ),
            ),
          
          // Loading indicator
          if (mapState.isLoading || busTrackingState.isLoading)
            const Positioned(
              top: 16,
              right: 16,
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showLegendDialog(context);
        },
        child: const Icon(Icons.info_outline),
        tooltip: 'Ver leyenda',
      ),
    );
  }

  Widget _buildMap(MapState mapState) {
    if (mapState.initialPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: mapState.initialPosition!,
        zoom: 12.0,
      ),
      markers: mapState.googleMapMarkers,
      polylines: mapState.googleMapPolylines,
      circles: mapState.circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      mapType: MapType.normal,
      onMapCreated: (controller) {
        ref.read(mapProvider.notifier).onMapCreated(controller);
      },
      onCameraMove: (position) {
        ref.read(mapProvider.notifier).onCameraMove(position);
      },
    );
  }

  Widget _buildActiveBusesPanel(BusTrackingState state) {
    return Container(
      color: Colors.white,
      height: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Autobuses activos: ${state.activeBuses.length}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Show all buses in a full screen list
                    _showAllBusesDialog(context, state);
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: state.activeBuses.length,
              itemBuilder: (context, index) {
                final busId = state.activeBuses.keys.elementAt(index);
                final bus = state.activeBuses[busId]!;
                
                // Find the assignment for this bus
                final assignment = state.activeAssignments.values.firstWhere(
                  (a) => a.busId == busId,
                  orElse: () => throw Exception('No assignment found for bus $busId'),
                );
                
                // Get last location if available
                final lastLocation = state.lastLocations[assignment.id];
                
                return _buildBusCard(
                  busId: busId,
                  bus: bus,
                  assignment: assignment,
                  lastLocation: lastLocation,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard({
    required String busId,
    required Bus bus,
    required Assignment assignment,
    custom_location.Location? lastLocation,
  }) {
    // Format last update time if available
    String lastUpdateText = 'Sin datos';
    if (lastLocation != null) {
      final now = DateTime.now();
      final difference = now.difference(lastLocation.timestamp);
      
      if (difference.inMinutes < 1) {
        lastUpdateText = 'Hace ${difference.inSeconds} segundos';
      } else if (difference.inHours < 1) {
        lastUpdateText = 'Hace ${difference.inMinutes} minutos';
      } else {
        lastUpdateText = 'Hace ${difference.inHours} horas';
      }
    }

    return GestureDetector(
      onTap: () {
        ref.read(busTrackingProvider.notifier).selectBus(busId);
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Unidad ${bus.busNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (assignment.routeName != null)
                    Text(
                      'Ruta: ${assignment.routeName}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lastUpdateText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (lastLocation?.speed != null)
                    Row(
                      children: [
                        Icon(Icons.speed, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${lastLocation!.speed!.toStringAsFixed(1)} km/h',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllBusesDialog(BuildContext context, BusTrackingState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autobuses Activos'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            itemCount: state.activeBuses.length,
            shrinkWrap: true,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final busId = state.activeBuses.keys.elementAt(index);
              final bus = state.activeBuses[busId]!;
              
              // Find the assignment for this bus
              final assignment = state.activeAssignments.values.firstWhere(
                (a) => a.busId == busId,
                orElse: () => throw Exception('No assignment found for bus $busId'),
              );
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.directions_bus, color: Colors.blue.shade700),
                ),
                title: Text('Unidad ${bus.busNumber}'),
                subtitle: Text(
                  assignment.routeName ?? 'Sin ruta asignada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(busTrackingProvider.notifier).selectBus(busId);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leyenda del Mapa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(
              icon: Icon(Icons.directions_bus, color: Colors.blue.shade700),
              text: 'Autobús en ruta',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: Icon(Icons.location_on, color: Colors.green.shade700),
              text: 'Parada de autobús',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: const Icon(Icons.location_on, color: Colors.red),
              text: 'Mi ubicación actual',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: Icon(Icons.linear_scale, color: Colors.blue.shade700),
              text: 'Recorrido de ruta',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: const Icon(Icons.linear_scale, color: Colors.red),
              text: 'Recorrido del autobús',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem({required Widget icon, required String text}) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}