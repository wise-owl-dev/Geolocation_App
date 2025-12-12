// lib/features/reports/screens/route_performance_report.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../services/report_export_service.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class RoutePerformanceReportScreen extends ConsumerStatefulWidget {
  const RoutePerformanceReportScreen({super.key});

  @override
  ConsumerState<RoutePerformanceReportScreen> createState() =>
      _RoutePerformanceReportScreenState();
}

class _RoutePerformanceReportScreenState
    extends ConsumerState<RoutePerformanceReportScreen> {
  final _exportService = ReportExportService();
  bool _isExporting = false;

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
          if (reportsState.routeMetrics.isNotEmpty && !_isExporting)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar',
              onPressed: () {
                _showExportDialog(context);
              },
            ),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Exportar Reporte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccione el formato de exportación:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Documento PDF'),
              subtitle: const Text('Formato profesional para imprimir'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Hoja de Cálculo CSV'),
              subtitle: const Text('Para análisis en Excel o Google Sheets'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('CSV');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(String format) async {
    final reportsState = ref.read(reportsProvider);
    
    if (reportsState.selectedStartDate == null || 
        reportsState.selectedEndDate == null) {
      _showErrorSnackBar('Error: No hay fechas seleccionadas');
      return;
    }

    setState(() => _isExporting = true);

    try {
      String filePath;
      
      if (format == 'PDF') {
        filePath = await _exportService.exportRoutePerformanceToPDF(
          metrics: reportsState.routeMetrics,
          startDate: reportsState.selectedStartDate!,
          endDate: reportsState.selectedEndDate!,
        );
      } else {
        filePath = await _exportService.exportRoutePerformanceToCSV(
          metrics: reportsState.routeMetrics,
          startDate: reportsState.selectedStartDate!,
          endDate: reportsState.selectedEndDate!,
        );
      }

      setState(() => _isExporting = false);

      if (mounted) {
        _showSuccessDialog(filePath, format);
      }
    } catch (e) {
      setState(() => _isExporting = false);
      _showErrorSnackBar('Error al exportar: $e');
    }
  }

  void _showSuccessDialog(String filePath, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
        title: const Text('Exportación Exitosa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El reporte se ha exportado correctamente en formato $format.'),
            const SizedBox(height: 8),
            Text(
              'Archivo guardado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _exportService.shareFile(filePath);
              } catch (e) {
                _showErrorSnackBar('Error al compartir: $e');
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}