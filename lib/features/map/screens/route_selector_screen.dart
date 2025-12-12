// lib/features/map/screens/route_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bus_tracking_provider.dart';
import '../providers/map_provider.dart';
import '../../../shared/models/route.dart' as app_route;

class RouteSelectionScreen extends ConsumerStatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  ConsumerState<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends ConsumerState<RouteSelectionScreen> {
  bool _isLoading = true;
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });

    // Cargar rutas disponibles
    await ref.read(mapProvider.notifier).loadRoutes();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _selectRoute(String routeId) {
    setState(() {
      _selectedRouteId = routeId;
    });
  }

  void _viewRouteOnMap() async {
    if (_selectedRouteId == null) {
      // Mostrar mensaje de error si no hay ruta seleccionada
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione una ruta primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Seleccionar la ruta en el provider y navegar al mapa
    await ref.read(mapProvider.notifier).selectRoute(_selectedRouteId!);
    
    if (mounted) {
      // Navegar a la pantalla de mapa
      context.push('/operator/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final routes = mapState.routes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Recorrido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar rutas',
            onPressed: _loadRoutes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : routes.isEmpty
              ? _buildEmptyState()
              : _buildRouteList(routes),
      bottomNavigationBar: _selectedRouteId != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No hay rutas disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intente actualizar o contacte al administrador',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRoutes,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList(List<app_route.Route> routes) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccione una ruta para ver su recorrido:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: routes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final route = routes[index];
                final isSelected = route.id == _selectedRouteId;
                
                return _buildRouteCard(route, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(app_route.Route route, bool isSelected) {
    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected ? const Color(0xFF191970) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: const Color(0xFF191970), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectRoute(route.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF191970),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.route,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Horario: ${route.startTime} - ${route.endTime}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (route.days.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Días: ${_formatDays(route.days)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Radio<String>(
                value: route.id,
                groupValue: _selectedRouteId,
                onChanged: (value) {
                  if (value != null) {
                    _selectRoute(value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _viewRouteOnMap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF191970),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Ver Recorrido en el Mapa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDays(List<String> days) {
    if (days.isEmpty) return 'No especificados';
    
    // Mapear abreviaturas de días a versiones cortas en español
    final Map<String, String> dayNames = {
      'MON': 'Lun',
      'TUE': 'Mar',
      'WED': 'Mié',
      'THU': 'Jue',
      'FRI': 'Vie',
      'SAT': 'Sáb',
      'SUN': 'Dom',
      // También mapear si están en español
      'LUN': 'Lun',
      'MAR': 'Mar',
      'MIÉ': 'Mié',
      'MIE': 'Mié',
      'JUE': 'Jue',
      'VIE': 'Vie',
      'SÁB': 'Sáb',
      'SAB': 'Sáb',
      'DOM': 'Dom',
    };
    
    final formattedDays = days.map((day) => dayNames[day.toUpperCase()] ?? day).join(', ');
    return formattedDays;
  }
}