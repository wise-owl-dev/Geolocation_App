// lib/features/reports/screens/route_performance_report.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class RoutePerformanceReportScreen extends ConsumerStatefulWidget {
  const RoutePerformanceReportScreen({super.key});

  @override
  ConsumerState<RoutePerformanceReportScreen> createState() =>
      _RoutePerformanceReportScreenState();
}

class _RoutePerformanceReportScreenState
    extends ConsumerState<RoutePerformanceReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).generateRoutePerformanceReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendimiento de Rutas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.read(reportsProvider.notifier).generateRoutePerformanceReport();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar',
            onPressed: () {
              _showExportDialog(context);
            },
          ),
        ],
      ),
      body: reportsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportsState.error != null
              ? _buildErrorState(reportsState.error!)
              : reportsState.routeMetrics.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(reportsState.routeMetrics),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el reporte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            CustomFilledButton(
              text: 'Reintentar',
              prefixIcon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                ref.read(reportsProvider.notifier).generateRoutePerformanceReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.blue.shade300),
            const SizedBox(height: 16),
            const Text(
              'No hay datos disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron datos para el período seleccionado',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<RouteMetrics> metrics) {
    // Calcular totales
    final totalTrips = metrics.fold<int>(0, (sum, m) => sum + m.totalTrips);
    final totalCompleted = metrics.fold<int>(0, (sum, m) => sum + m.completedTrips);
    final totalCancelled = metrics.fold<int>(0, (sum, m) => sum + m.cancelledTrips);
    final avgSpeed = metrics.isEmpty
        ? 0.0
        : metrics.fold<double>(0, (sum, m) => sum + m.averageSpeed) / metrics.length;
    final avgOnTime = metrics.isEmpty
        ? 0.0
        : metrics.fold<double>(0, (sum, m) => sum + m.onTimePercentage) / metrics.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          const Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryCards(
            totalTrips: totalTrips,
            totalCompleted: totalCompleted,
            totalCancelled: totalCancelled,
            avgSpeed: avgSpeed,
            avgOnTime: avgOnTime,
          ),

          const SizedBox(height: 24),

          // Detalles por ruta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detalles por Ruta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${metrics.length} rutas',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de rutas
          ...metrics.map((metric) => _buildRouteCard(metric)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int totalTrips,
    required int totalCompleted,
    required int totalCancelled,
    required double avgSpeed,
    required double avgOnTime,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.route,
                title: 'Total Viajes',
                value: totalTrips.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.check_circle,
                title: 'Completados',
                value: totalCompleted.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.cancel,
                title: 'Cancelados',
                value: totalCancelled.toString(),
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.speed,
                title: 'Vel. Promedio',
                value: '${avgSpeed.toStringAsFixed(1)} km/h',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          icon: Icons.schedule,
          title: 'Puntualidad Promedio',
          value: '${avgOnTime.toStringAsFixed(1)}%',
          color: Colors.purple,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteMetrics metric) {
    final completionRate = metric.totalTrips > 0
        ? (metric.completedTrips / metric.totalTrips * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.route, color: Colors.blue.shade700),
        ),
        title: Text(
          metric.routeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${metric.totalTrips} viajes • ${completionRate.toStringAsFixed(1)}% completados',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMetricRow(
                  'Viajes Totales',
                  metric.totalTrips.toString(),
                  Icons.route,
                ),
                const Divider(),
                _buildMetricRow(
                  'Completados',
                  metric.completedTrips.toString(),
                  Icons.check_circle,
                  valueColor: Colors.green,
                ),
                const Divider(),
                _buildMetricRow(
                  'Cancelados',
                  metric.cancelledTrips.toString(),
                  Icons.cancel,
                  valueColor: Colors.red,
                ),
                const Divider(),
                _buildMetricRow(
                  'Velocidad Promedio',
                  '${metric.averageSpeed.toStringAsFixed(1)} km/h',
                  Icons.speed,
                ),
                const Divider(),
                _buildMetricRow(
                  'Puntualidad',
                  '${metric.onTimePercentage.toStringAsFixed(1)}%',
                  Icons.schedule,
                  valueColor: metric.onTimePercentage >= 80
                      ? Colors.green
                      : metric.onTimePercentage >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: metric.onTimePercentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: metric.onTimePercentage >= 80
                      ? Colors.green
                      : metric.onTimePercentage >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Reporte'),
        content: const Text(
          '¿En qué formato desea exportar el reporte?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportReport('PDF');
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportReport('CSV');
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _exportReport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando reporte en formato $format...'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {},
        ),
      ),
    );
    // Implementar lógica de exportación
  }
}