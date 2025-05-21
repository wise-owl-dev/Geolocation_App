// lib/features/map/screens/operator_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/bus_tracking_provider.dart';
import '../providers/map_provider.dart';
import '../providers/location_provider.dart';
import '../../operator/providers/operator_schedules_provider.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class OperatorMapScreen extends ConsumerStatefulWidget {
  final String? assignmentId;

  const OperatorMapScreen({
    Key? key,
    this.assignmentId,
  }) : super(key: key);

  @override
  ConsumerState<OperatorMapScreen> createState() => _OperatorMapScreenState();
}

class _OperatorMapScreenState extends ConsumerState<OperatorMapScreen> {
  Assignment? _activeAssignment;
  bool _isStarted = false;
  bool _isTrackingLocation = false;
  bool _isLoading = true;
  bool _isLocating = false;
  String? _error;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _loadData();
    }
  });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load assignment data if an ID was provided
      if (widget.assignmentId != null) {
        await _loadAssignment(widget.assignmentId!);
      } else {
        // Load all assignments for the operator and find an active one
        await _loadOperatorAssignments();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar datos: $e';
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _loadAssignment(String assignmentId) async {
    try {
      // Use Supabase to fetch the assignment data
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('asignaciones')
          .select('''
            *,
            autobuses:autobus_id (*),
            recorridos:recorrido_id (*)
          ''')
          .eq('id', assignmentId)
          .single();

      // Process assignment data
      if (result != null) {
        final busData = result['autobuses'];
        final routeData = result['recorridos'];

        // Create assignment object
        _activeAssignment = Assignment.fromJson(
          result,
          busNumber: busData?['numero_unidad'],
          routeName: routeData?['nombre'],
        );

        // Load route stops on map
        if (_activeAssignment?.routeId != null) {
          await ref.read(mapProvider.notifier).selectRoute(_activeAssignment!.routeId);
        }
      }
    } catch (e) {
      throw Exception('Error al cargar la asignación: $e');
    }
  }

  Future<void> _loadOperatorAssignments() async {
    try {
      // Load assignments from operator schedules provider
      final operatorSchedulesState = ref.read(operatorSchedulesProvider);

      // Find an active assignment (programmed or in progress for today)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      Assignment? activeAssignment;

      for (final assignment in operatorSchedulesState.assignments) {
        // Check if assignment is for today
        if (assignment.startDate.year == today.year &&
            assignment.startDate.month == today.month &&
            assignment.startDate.day == today.day) {
          // Check if status is programmed or in progress
          if (assignment.status == AssignmentStatus.programada ||
              assignment.status == AssignmentStatus.en_curso) {
            activeAssignment = assignment;
            break;
          }
        }
      }

      if (activeAssignment != null) {
        _activeAssignment = activeAssignment;

        // Load route on map
        if (_activeAssignment?.routeId != null) {
          await ref.read(mapProvider.notifier).selectRoute(_activeAssignment!.routeId);
        }
      } else {
        _error = 'No tiene asignaciones activas para hoy';
      }
    } catch (e) {
      throw Exception('Error al cargar las asignaciones: $e');
    }
  }

  Future<void> _startRoute() async {
  if (_activeAssignment == null) return;

  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    // Solo iniciar el seguimiento si tenemos una asignación activa
    // Actualizar el estado de la asignación a "en curso" en la base de datos
    final supabase = Supabase.instance.client;
    await supabase
        .from('asignaciones')
        .update({
          'estado': 'en_curso',
          'ultima_actualizacion': DateTime.now().toIso8601String(),  // Añadir timestamp
        })
        .eq('id', _activeAssignment!.id);

    // Iniciar el seguimiento de ubicación
    await ref.read(locationProvider.notifier).startTracking(_activeAssignment!.id);

    setState(() {
      _isLoading = false;
      _isStarted = true;
      _isTrackingLocation = true;
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Ruta iniciada! Tu ubicación se está compartiendo.'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    setState(() {
      _isLoading = false;
      _error = 'Error al iniciar la ruta: $e';
    });
    print('Error starting route: $e');
  }
}

  Future<void> _completeRoute() async {
    if (_activeAssignment == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Stop tracking location
      ref.read(locationProvider.notifier).stopTracking();

      // Update assignment status to "completed" in database
      final supabase = Supabase.instance.client;
      await supabase
          .from('asignaciones')
          .update({'estado': 'completada'})
          .eq('id', _activeAssignment!.id);

      setState(() {
        _isLoading = false;
        _isStarted = false;
        _isTrackingLocation = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta completada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      if (context.mounted) {
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al completar la ruta: $e';
      });
      print('Error completing route: $e');
    }
  }

  Future<void> _toggleTracking() async {
    if (!_isStarted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isTrackingLocation) {
        // Pause tracking
        ref.read(locationProvider.notifier).stopTracking();
        setState(() {
          _isTrackingLocation = false;
        });
      } else {
        // Resume tracking
        await ref.read(locationProvider.notifier).startTracking(_activeAssignment!.id);
        setState(() {
          _isTrackingLocation = true;
        });
      }

      setState(() {
        _isLoading = false;
      });

      // Show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTrackingLocation
              ? 'Compartiendo ubicación...'
              : 'Ubicación pausada'),
          backgroundColor: _isTrackingLocation ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cambiar el estado del rastreo: $e';
      });
      print('Error toggling tracking: $e');
    }
  }
  
  // Nuevo método para ir a la ubicación del usuario
  Future<void> _goToMyLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      // Forzar actualización de la ubicación actual
      final currentLocation = await ref.read(locationProvider.notifier).getCurrentLocation();
      
      if (currentLocation != null && _mapController != null) {
        // Usar el controlador directamente para mayor control
        await _mapController!.animateCamera(
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
        title: Text(_activeAssignment?.routeName != null
            ? 'Ruta: ${_activeAssignment!.routeName}'
            : 'Mi Ruta'),
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
          _buildMap(mapState),

          // Assignment info panel
          if (_activeAssignment != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildAssignmentInfoCard(),
            ),

          // Controls panel
          if (_activeAssignment != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildControlsPanel(),
            ),

          // Error message
          if (_error != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
        // Guardar referencia al controlador del mapa
        _mapController = controller;
        ref.read(mapProvider.notifier).onMapCreated(controller);
      },
      onCameraMove: (position) {
        ref.read(mapProvider.notifier).onCameraMove(position);
      },
    );
  }

  Widget _buildAssignmentInfoCard() {
    if (_activeAssignment == null) return const SizedBox.shrink();

    // Format time
    final timeFormat = (TimeOfDay time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    final startTime = timeFormat(_activeAssignment!.startTime);
    final endTime = timeFormat(_activeAssignment!.endTime);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unidad: ${_activeAssignment!.busNumber ?? 'No asignada'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Horario: $startTime - $endTime',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeAssignment!.status.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _activeAssignment!.status.displayName,
                    style: TextStyle(
                      color: _activeAssignment!.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location status
            if (_isStarted)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _isTrackingLocation
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isTrackingLocation ? Icons.location_on : Icons.location_off,
                      color: _isTrackingLocation ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isTrackingLocation
                            ? 'Compartiendo ubicación en tiempo real'
                            : 'Compartición de ubicación pausada',
                        style: TextStyle(
                          color: _isTrackingLocation ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                if (!_isStarted)
                  Expanded(
                    child: CustomFilledButton(
                      text: 'Iniciar Ruta',
                      backgroundColor: Colors.green,
                      prefixIcon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: _startRoute,
                    ),
                  )
                else ...[
                  // Toggle tracking button
                  Expanded(
                    child: CustomFilledButton(
                      text: _isTrackingLocation ? 'Pausar Ubicación' : 'Reanudar Ubicación',
                      backgroundColor: _isTrackingLocation ? Colors.orange : Colors.blue,
                      prefixIcon: Icon(
                        _isTrackingLocation ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _toggleTracking,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Complete route button
                  Expanded(
                    child: CustomFilledButton(
                      text: 'Finalizar Ruta',
                      backgroundColor: Colors.red,
                      prefixIcon: const Icon(Icons.stop, color: Colors.white),
                      onPressed: _completeRoute,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}