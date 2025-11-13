// lib/features/admin/screens/route/route_stops_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/bus_stop.dart';
import '../../../../shared/widgets/widgets.dart';

class RouteStop {
  final String id;
  final String routeId;
  final String stopId;
  final int order;
  final int? estimatedTime;
  
  RouteStop({
    required this.id,
    required this.routeId,
    required this.stopId,
    required this.order,
    this.estimatedTime,
  });
}

class RouteStopsScreen extends ConsumerStatefulWidget {
  final String routeId;
  
  const RouteStopsScreen({
    super.key,
    required this.routeId,
  });

  @override
  ConsumerState<RouteStopsScreen> createState() => _RouteStopsScreenState();
}

class _RouteStopsScreenState extends ConsumerState<RouteStopsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _routeName = "";
  List<RouteStop> _routeStops = [];
  Map<String, BusStop> _busStops = {};
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // 1. Obtener información del recorrido
      final routeResult = await _supabase
          .from('recorridos')
          .select()
          .eq('id', widget.routeId)
          .single();
      
      _routeName = routeResult['nombre'];
      
      // 2. Obtener las paradas del recorrido
      final routeStopsResult = await _supabase
          .from('recorrido_paradas')
          .select()
          .eq('recorrido_id', widget.routeId)
          .order('orden');
      
      // Transformar los datos
      _routeStops = routeStopsResult.map<RouteStop>((data) => RouteStop(
        id: data['id'],
        routeId: data['recorrido_id'],
        stopId: data['parada_id'],
        order: data['orden'],
        estimatedTime: data['tiempo_estimado'],
      )).toList();
      
      // 3. Obtener datos de las paradas
      _busStops = {};
      for (var routeStop in _routeStops) {
        try {
          final stopData = await _supabase
              .from('paradas')
              .select()
              .eq('id', routeStop.stopId)
              .single();
          
          _busStops[routeStop.stopId] = BusStop.fromJson(stopData);
        } catch (e) {
          print('Error al cargar parada ${routeStop.stopId}: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar los datos: $e';
        });
      }
    }
  }
  
  void _showAddStopDialog() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Obtener todas las paradas
      final stopsResult = await _supabase
          .from('paradas')
          .select()
          .eq('estado', 'activo')
          .order('nombre');
      
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Filtrar paradas que no están en el recorrido
      List<dynamic> availableStops = stopsResult.where((stop) {
        final stopId = stop['id'];
        return !_routeStops.any((rs) => rs.stopId == stopId);
      }).toList();
      
      if (availableStops.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay paradas disponibles para añadir'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Variables para el diálogo
      String? selectedStopId;
      int estimatedTime = 0;
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Añadir Parada al Recorrido'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccione una parada',
                    border: OutlineInputBorder(),
                  ),
                  items: availableStops.map((stop) {
                    return DropdownMenuItem<String>(
                      value: stop['id'],
                      child: Text(stop['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStopId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tiempo estimado (minutos)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: estimatedTime.toString(),
                  onChanged: (value) {
                    estimatedTime = int.tryParse(value) ?? 0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedStopId != null) {
                  Navigator.pop(dialogContext);
                  
                  try {
                    // Obtener el siguiente orden disponible
                    int nextOrder = 1;
                    if (_routeStops.isNotEmpty) {
                      nextOrder = _routeStops.map((rs) => rs.order).reduce((a, b) => a > b ? a : b) + 1;
                    }
                    
                    // Añadir la parada al recorrido
                    final result = await _supabase.from('recorrido_paradas').insert({
                      'recorrido_id': widget.routeId,
                      'parada_id': selectedStopId,
                      'orden': nextOrder,
                      'tiempo_estimado': estimatedTime > 0 ? estimatedTime : null,
                    }).select();
                    
                    // Obtener datos de la parada
                    final stopData = await _supabase
                        .from('paradas')
                        .select()
                        .eq('id', selectedStopId!)
                        .single();
                    
                    // Actualizar la UI
                    if (mounted) {
                      setState(() {
                        _routeStops.add(RouteStop(
                          id: result[0]['id'],
                          routeId: widget.routeId,
                          stopId: selectedStopId!,
                          order: nextOrder,
                          estimatedTime: estimatedTime > 0 ? estimatedTime : null,
                        ));
                        
                        _busStops[selectedStopId!] = BusStop.fromJson(stopData);
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Parada añadida correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error al añadir parada: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al añadir parada: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, seleccione una parada'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      if (mounted) Navigator.pop(context);
      
      print('Error al cargar paradas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar paradas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _removeStop(RouteStop routeStop) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eliminando parada...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Eliminar la parada del recorrido
      await _supabase
          .from('recorrido_paradas')
          .delete()
          .eq('id', routeStop.id);
      
      // Actualizar la UI
      if (mounted) {
        setState(() {
          _routeStops.removeWhere((rs) => rs.id == routeStop.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parada eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar parada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar parada: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paradas de $_routeName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStopDialog,
        tooltip: 'Añadir parada',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar los datos',
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
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _routeStops.isEmpty
                  ? _buildEmptyState()
                  : _buildStopsList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay paradas asignadas a este recorrido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añada paradas usando el botón +',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStopsList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _routeStops.length,
      onReorder: (oldIndex, newIndex) async {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        // Reorganizar la lista localmente
        final item = _routeStops.removeAt(oldIndex);
        _routeStops.insert(newIndex, item);
        
        // Mostrar indicador
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualizando orden...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Actualizar el orden en la base de datos
        try {
          for (int i = 0; i < _routeStops.length; i++) {
            await _supabase
                .from('recorrido_paradas')
                .update({'orden': i + 1})
                .eq('id', _routeStops[i].id);
            
            // Actualizar el orden local
            _routeStops[i] = RouteStop(
              id: _routeStops[i].id,
              routeId: _routeStops[i].routeId,
              stopId: _routeStops[i].stopId,
              order: i + 1,
              estimatedTime: _routeStops[i].estimatedTime,
            );
          }
          
          // Forzar actualización de UI
          if (mounted) setState(() {});
        } catch (e) {
          print('Error al actualizar orden: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar orden: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      itemBuilder: (context, index) {
        final routeStop = _routeStops[index];
        final busStop = _busStops[routeStop.stopId];
        
        return Card(
          key: Key(routeStop.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade700,
              child: Text('${routeStop.order}'),
            ),
            title: Text(busStop?.name ?? 'Parada desconocida'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (busStop != null) ...[
                  Text('Lat: ${busStop.latitude.toStringAsFixed(6)}, Lon: ${busStop.longitude.toStringAsFixed(6)}'),
                  if (routeStop.estimatedTime != null)
                    Text('Tiempo estimado: ${routeStop.estimatedTime} min'),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Mostrar diálogo de confirmación
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar parada'),
                    content: Text('¿Está seguro de eliminar "${busStop?.name ?? 'esta parada'}" del recorrido?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _removeStop(routeStop);
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}