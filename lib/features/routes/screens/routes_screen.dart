// lib/features/routes/screens/routes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/routes_provider.dart';
import '../widgets/route_card.dart';
import '../../../shared/widgets/loading_overlay.dart';

class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Cargar rutas al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routesProvider.notifier).loadRoutes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    ref.read(routesProvider.notifier).searchRoutes(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    ref.read(routesProvider.notifier).loadRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar rutas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                style: const TextStyle(color: Colors.black),
                autofocus: true,
                onSubmitted: (_) => _handleSearch(),
              )
            : const Text('Rutas de Autobús'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Contenido principal
          Column(
            children: [
              // Encabezado de información
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF191970),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Selecciona una ruta para ver su recorrido y paradas',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de rutas
              Expanded(
                child: routesState.isLoading && routesState.routes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : routesState.error != null
                        ? _buildErrorMessage(routesState.error!)
                        : routesState.routes.isEmpty
                            ? _buildEmptyState()
                            : _buildRoutesList(routesState.routes),
              ),
            ],
          ),
          
          // Indicador de carga
          if (routesState.isLoading && routesState.routes.isNotEmpty)
            const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRoutesList(List<dynamic> routes) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final route = routes[index];
        return RouteCard(
          route: route,
          onTap: () {
            // Navegar a la pantalla de detalles de ruta
            context.push('/user/route-details/${route.id}');
          },
        );
      },
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
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? 'No se encontraron rutas para tu búsqueda'
                : 'No hay rutas disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          if (_isSearching)
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Mostrar todas las rutas'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar rutas',
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
            onPressed: () => ref.read(routesProvider.notifier).loadRoutes(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}