// lib/features/map/widgets/route_selector.dart
import 'package:flutter/material.dart';
import '../../../shared/models/route.dart' as app_route;

class RouteSelector extends StatelessWidget {
  final List<app_route.Route> routes;
  final String? selectedRouteId;
  final Function(String) onRouteSelected;
  final VoidCallback onClearRoute;

  const RouteSelector({
    super.key,
    required this.routes,
    this.selectedRouteId,
    required this.onRouteSelected,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected route display or dropdown
          if (selectedRouteId != null) 
            _buildSelectedRoute(context)
          else 
            _buildRouteDropdown(context),
        ],
      ),
    );
  }

  Widget _buildSelectedRoute(BuildContext context) {
    // Find the selected route
    final selectedRoute = routes.firstWhere(
      (route) => route.id == selectedRouteId,
      orElse: () => app_route.Route(
        id: '',
        name: 'Ruta Desconocida',
        startTime: '',
        endTime: '',
        days: [],
        status: 'activo',
      ),
    );

    return ListTile(
      leading: Icon(Icons.route, color: const Color(0xFF191970)),
      title: Text(
        selectedRoute.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Horario: ${selectedRoute.startTime} - ${selectedRoute.endTime}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClearRoute,
        tooltip: 'Quitar filtro de ruta',
      ),
    );
  }

  Widget _buildRouteDropdown(BuildContext context) {
    if (routes.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('No hay rutas disponibles'),
      );
    }

    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Seleccione una ruta para ver su recorrido'),
          ),
          value: null,
          items: routes.map((route) {
            return DropdownMenuItem<String>(
              value: route.id,
              child: Row(
                children: [
                  Icon(Icons.route, color: const Color(0xFF191970), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Horario: ${route.startTime} - ${route.endTime}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onRouteSelected(value);
            }
          },
        ),
      ),
    );
  }
}