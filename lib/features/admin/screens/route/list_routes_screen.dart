import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../providers/route/routes_provider.dart';


class RoutesListScreen extends ConsumerStatefulWidget {
  const RoutesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoutesListScreen> createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends ConsumerState<RoutesListScreen> {
  @override
  void initState() {
    super.initState();
    // Load routes when screen starts
    Future.microtask(() {
      ref.read(routesProvider.notifier).loadRoutes();
    });
  }

  // Method to show delete confirmation dialog
  Future<void> _confirmDeleteRoute(BuildContext context, String routeId, String routeName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar el recorrido "$routeName"?'),
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
                    content: Text('Eliminando recorrido...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Delete the route
                await ref.read(routesProvider.notifier).deleteRoute(routeId);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recorrido eliminado exitosamente'),
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
    final routesState = ref.watch(routesProvider);
    
    // Show SnackBar if there's an error
    if (routesState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(routesState.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Recorridos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(routesProvider.notifier).loadRoutes();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Routes list
              Expanded(
                child: routesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : routesState.routes.isEmpty
                        ? _buildEmptyState()
                        : _buildRoutesList(routesState),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomFilledButton(
                      height: 60,
                      text: 'Agregar Recorrido',
                      prefixIcon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        // Navigate to add route screen
                        final result = await context.push('/admin/add-route');
                        // If we return with success, reload the list
                        if (result == true && mounted) {
                          ref.read(routesProvider.notifier).loadRoutes();
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
            Icons.route_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay recorridos registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega un nuevo recorrido con el botón inferior',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoutesList(RoutesState state) {
    return ListView.separated(
      itemCount: state.routes.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final route = state.routes[index];
        
        // Status color based on the route status
        Color statusColor = route.status == 'activo' ? Colors.green : Colors.red;
        
        // Format days for display
        final daysText = _formatDays(route.days);
        
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
                Icons.route,
                color: Colors.blue,
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Horario: ${route.startTime} - ${route.endTime}', 
                               style: const TextStyle(fontSize: 12)),
                          Text('Días: $daysText', 
                               style: const TextStyle(fontSize: 12)),
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
                        route.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (route.description != null && route.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      route.description!,
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
                // Botón de ver/editar paradas
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.purple),
                  tooltip: 'Gestionar paradas',
                  onPressed: () {
                    // Navegar a la pantalla de paradas del recorrido
                    context.push('/admin/route-stops/${route.id}');
                  },
                ),
                // Botón de editar (existente)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final result = await context.push('/admin/edit-route/${route.id}');
                    if (result == true && mounted) {
                      ref.read(routesProvider.notifier).loadRoutes();
                    }
                  },
                ),
                // Botón de eliminar (existente)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _confirmDeleteRoute(context, route.id, route.name);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to format days
  String _formatDays(List<String> days) {
    if (days.isEmpty) return 'Ninguno';
    
    // Map days to short forms
    final Map<String, String> dayShortNames = {
      'lunes': 'Lun',
      'martes': 'Mar',
      'miércoles': 'Mié',
      'jueves': 'Jue',
      'viernes': 'Vie',
      'sábado': 'Sáb',
      'domingo': 'Dom',
    };
    
    // Format days
    return days.map((day) => dayShortNames[day] ?? day.substring(0, 3)).join(', ');
  }
}