import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bus_search_provider.dart';
import '../../../shared/models/bus.dart';
import '../../../shared/widgets/widgets.dart';

class BusSearchScreen extends ConsumerStatefulWidget {
  const BusSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BusSearchScreen> createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends ConsumerState<BusSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        ref.read(busSearchProvider.notifier).clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(busSearchProvider.notifier).searchBusByNumber(query);
    }
  }

  void _showAllBuses() {
    setState(() {
      _showAll = true;
    });
    ref.read(busSearchProvider.notifier).loadAllBuses();
  }

  @override
  Widget build(BuildContext context) {
    final busSearchState = ref.watch(busSearchProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Autobús'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Sección de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encuentra tu autobús',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa el número de unidad o busca todos los autobuses disponibles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo de búsqueda
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Número de unidad',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: _performSearch,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón para mostrar todos los autobuses
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _showAllBuses,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                    child: Text(
                      'Ver todos los autobuses',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Línea divisoria
          Divider(color: Colors.grey.shade300, height: 1),
          
          // Resultados de la búsqueda
          Expanded(
            child: busSearchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : busSearchState.error != null
                    ? _buildErrorView(busSearchState.error!)
                    : busSearchState.buses.isEmpty && !_showAll
                        ? _buildEmptyState()
                        : _buildResultsList(busSearchState.buses),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Busca un autobús por su número',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el número de unidad o explora todos los autobuses',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error en la búsqueda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _performSearch,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsList(List<Bus> buses) {
    if (buses.isEmpty && _showAll) {
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
              'No hay autobuses disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: buses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bus = buses[index];
        
        // Color según el estado del autobús
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.directions_bus,
                color: Colors.blue.shade800,
                size: 28,
              ),
            ),
            title: Text(
              'Unidad ${bus.busNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Placa: ${bus.licensePlate}'),
                Text('${bus.brand} ${bus.model} ${bus.year}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
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
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () {
              // Aquí podríamos navegar a una pantalla de detalles del autobús
              // Por ejemplo: context.push('/user/bus-details/${bus.id}');
              
              // Por ahora, solo mostraremos un mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Información del autobús ${bus.busNumber}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }
}