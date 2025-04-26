import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/shared/widgets/widgets.dart';

import '../../providers/bus_stop/busstops_provider.dart';

class BusStopsListScreen extends ConsumerStatefulWidget {
  const BusStopsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BusStopsListScreen> createState() => _BusStopsListScreenState();
}

class _BusStopsListScreenState extends ConsumerState<BusStopsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load bus stops when screen starts
    Future.microtask(() {
      ref.read(busStopsProvider.notifier).loadBusStops();
    });
  }

  // Method to show delete confirmation dialog
  Future<void> _confirmDeleteBusStop(BuildContext context, String busStopId, String busStopName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar la parada "$busStopName"?'),
                const SizedBox(height: 8),
                const Text('Esta acción no se puede deshacer.', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Close the dialog first
                Navigator.of(dialogContext).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Eliminando parada...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Delete the bus stop
                await ref.read(busStopsProvider.notifier).deleteBusStop(busStopId);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parada eliminada exitosamente'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busStopsState = ref.watch(busStopsProvider);
    
    // Show SnackBar if there's an error
    if (busStopsState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(busStopsState.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Paradas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(busStopsProvider.notifier).loadBusStops();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus stops list
              Expanded(
                child: busStopsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : busStopsState.busStops.isEmpty
                        ? _buildEmptyState()
                        : _buildBusStopsList(busStopsState),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomFilledButton(
                      height: 60,
                      text: 'Agregar Parada',
                      prefixIcon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        // Navigate to add bus stop screen
                        final result = await context.push('/admin/add-busstop');
                        // If we return with success, reload the list
                        if (result == true && mounted) {
                          ref.read(busStopsProvider.notifier).loadBusStops();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay paradas registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega una nueva parada con el botón inferior',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusStopsList(BusStopsState state) {
    return ListView.separated(
      itemCount: state.busStops.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final busStop = state.busStops[index];
        
        // Status color based on the bus stop status
        Color statusColor = busStop.status == 'activo' ? Colors.green : Colors.red;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
              ),
            ),
            title: Text(
              busStop.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lat: ${busStop.latitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
                          Text('Lon: ${busStop.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        busStop.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (busStop.address != null && busStop.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      busStop.address!,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    // Navigate to edit screen
                    final result = await context.push('/admin/edit-busstop/${busStop.id}');
                    // If we return with success, reload the list
                    if (result == true && mounted) {
                      ref.read(busStopsProvider.notifier).loadBusStops();
                    }
                  },
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Show confirmation dialog
                    _confirmDeleteBusStop(
                      context, 
                      busStop.id, 
                      busStop.name
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}