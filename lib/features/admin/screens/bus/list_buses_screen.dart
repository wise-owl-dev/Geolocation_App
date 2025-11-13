import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bus/buses_provider.dart';
import '../../../../shared/widgets/custom_filled_button.dart';

class BusesListScreen extends ConsumerStatefulWidget {
  const BusesListScreen({super.key});

  @override
  ConsumerState<BusesListScreen> createState() => _BusesListScreenState();
}

class _BusesListScreenState extends ConsumerState<BusesListScreen> {
  @override
  void initState() {
    super.initState();
    // Load buses when screen starts
    Future.microtask(() {
      ref.read(busesProvider.notifier).loadBuses();
    });
  }

  // Method to show delete confirmation dialog
  Future<void> _confirmDeleteBus(BuildContext context, String busId, String busNumber) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar el autobús $busNumber?'),
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
                    content: Text('Eliminando autobús...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Delete the bus
                await ref.read(busesProvider.notifier).deleteBus(busId);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Autobús eliminado exitosamente'),
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
    final busesState = ref.watch(busesProvider);
    
    // Show SnackBar if there's an error
    if (busesState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(busesState.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Autobuses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(busesProvider.notifier).loadBuses();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buses list
              Expanded(
                child: busesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : busesState.buses.isEmpty
                        ? _buildEmptyState()
                        : _buildBusesList(busesState),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomFilledButton(
                      height: 60,
                      text: 'Agregar Autobús',
                      prefixIcon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        // Navigate to add bus screen
                        final result = await context.push('/admin/add-bus');
                        // If we return with success, reload the list
                        if (result == true && mounted) {
                          ref.read(busesProvider.notifier).loadBuses();
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
            Icons.directions_bus_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay autobuses registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega un nuevo autobús con el botón inferior',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusesList(BusesState state) {
    return ListView.separated(
      itemCount: state.buses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final bus = state.buses[index];
        
        // Status color based on the bus status
        Color statusColor;
        switch(bus.status) {
          case 'activo':
            statusColor = Colors.green;
            break;
          case 'inactivo':
            statusColor = Colors.red;
            break;
          case 'mantenimiento':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }
        
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
                Icons.directions_bus,
                color: Colors.blue,
              ),
            ),
            title: Text(
              'Unidad: ${bus.busNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Placa: ${bus.licensePlate}'),
                Text('${bus.brand} ${bus.model} ${bus.year}'),
                Row(
                  children: [
                    Text('Capacidad: ${bus.capacity} pasajeros'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bus.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón para asignar
                IconButton(
                  icon: const Icon(Icons.assignment, color: Colors.purple),
                  tooltip: 'Asignar a operador',
                  onPressed: () {
                    _showAssignOperatorDialog(context, bus.id, bus.busNumber);
                  },
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    // Navigate to edit screen
                    final result = await context.push('/admin/edit-bus/${bus.id}');
                    // If we return with success, reload the list
                    if (result == true && mounted) {
                      ref.read(busesProvider.notifier).loadBuses();
                    }
                  },
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Show confirmation dialog
                    _confirmDeleteBus(
                      context, 
                      bus.id, 
                      bus.busNumber
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

  void _showAssignOperatorDialog(BuildContext context, String busId, String busNumber) async {
  // Navegar a la pantalla de creación de asignación con el autobús preseleccionado
  final result = await context.push('/admin/add-assignment?busId=$busId');
  if (result == true && mounted) {
    // Recargar la lista si es necesario
    ref.read(busesProvider.notifier).loadBuses();
  }
}
}