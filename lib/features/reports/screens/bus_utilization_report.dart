// lib/features/reports/screens/bus_utilization_report.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reports_provider.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class BusUtilizationReportScreen extends ConsumerStatefulWidget {
  const BusUtilizationReportScreen({super.key});

  @override
  ConsumerState<BusUtilizationReportScreen> createState() =>
      _BusUtilizationReportScreenState();
}

class _BusUtilizationReportScreenState
    extends ConsumerState<BusUtilizationReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).generateBusUtilizationReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilización de Autobuses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.read(reportsProvider.notifier).generateBusUtilizationReport();
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
              : reportsState.busUtilization == null
                  ? _buildEmptyState()
                  : _buildContent(reportsState.busUtilization!),
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
                ref.read(reportsProvider.notifier).generateBusUtilizationReport();
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

  Widget _buildContent(Map<String, dynamic> data) {
    final totalBuses = data['total_buses'] as int;
    final activeBuses = data['active_buses'] as int;
    final utilizationRate = data['utilization_rate'] as double;
    final totalTrips = data['total_trips'] as int;
    final completedTrips = data['completed_trips'] as int;
    final cancelledTrips = data['cancelled_trips'] as int;

    final inactiveBuses = totalBuses - activeBuses;
    final completionRate = totalTrips > 0 ? (completedTrips / totalTrips * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de utilización principal
          const Text(
            'Tasa de Utilización',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildUtilizationGauge(utilizationRate),

          const SizedBox(height: 24),

          // Resumen de flota
          const Text(
            'Resumen de Flota',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildFleetCard(
                  icon: Icons.directions_bus,
                  title: 'Total Autobuses',
                  value: totalBuses.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFleetCard(
                  icon: Icons.check_circle,
                  title: 'En Operación',
                  value: activeBuses.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildFleetCard(
                  icon: Icons.cancel,
                  title: 'Inactivos',
                  value: inactiveBuses.toString(),
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFleetCard(
                  icon: Icons.route,
                  title: 'Viajes Totales',
                  value: totalTrips.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico de distribución
          const Text(
            'Distribución de la Flota',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildDistributionChart(activeBuses, inactiveBuses),

          const SizedBox(height: 24),

          // Eficiencia de viajes
          const Text(
            'Eficiencia de Viajes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProgressBar(
                    label: 'Completados',
                    value: completedTrips,
                    total: totalTrips,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    label: 'Cancelados',
                    value: cancelledTrips,
                    total: totalTrips,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    label: 'En curso',
                    value: totalTrips - completedTrips - cancelledTrips,
                    total: totalTrips,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recomendaciones
          _buildRecommendations(utilizationRate, completionRate),
        ],
      ),
    );
  }

  Widget _buildUtilizationGauge(double utilizationRate) {
    Color gaugeColor;
    String status;

    if (utilizationRate >= 80) {
      gaugeColor = Colors.green;
      status = 'Excelente';
    } else if (utilizationRate >= 60) {
      gaugeColor = Colors.lightGreen;
      status = 'Buena';
    } else if (utilizationRate >= 40) {
      gaugeColor = Colors.orange;
      status = 'Regular';
    } else {
      gaugeColor = Colors.red;
      status = 'Baja';
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: utilizationRate / 100,
                    strokeWidth: 20,
                    backgroundColor: Colors.grey.shade200,
                    color: gaugeColor,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${utilizationRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: gaugeColor,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Porcentaje de autobuses en operación',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(int active, int inactive) {
    final total = active + inactive;
    final activePercentage = total > 0 ? (active / total * 100) : 0.0;
    final inactivePercentage = 100 - activePercentage;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: active,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${activePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (inactive > 0)
                  Expanded(
                    flex: inactive,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${inactivePercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('En operación', Colors.green, active),
                _buildLegendItem('Inactivos', Colors.red, inactive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$value de $total (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(double utilizationRate, double completionRate) {
    final recommendations = <Map<String, dynamic>>[];

    if (utilizationRate < 60) {
      recommendations.add({
        'icon': Icons.trending_up,
        'color': Colors.orange,
        'title': 'Baja utilización de flota',
        'description':
            'Considere optimizar las rutas o aumentar la frecuencia de servicios para aprovechar mejor la capacidad disponible.',
      });
    }

    if (completionRate < 80) {
      recommendations.add({
        'icon': Icons.warning,
        'color': Colors.red,
        'title': 'Tasa de cancelación alta',
        'description':
            'Revise las causas de cancelaciones frecuentes y tome medidas correctivas.',
      });
    }

    if (utilizationRate >= 90) {
      recommendations.add({
        'icon': Icons.add_circle,
        'color': Colors.blue,
        'title': 'Alta demanda',
        'description':
            'La flota está operando casi a máxima capacidad. Considere expandir la flota si la demanda continúa.',
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': 'Operación óptima',
        'description':
            'La utilización de la flota está en niveles saludables. Continúe monitoreando para mantener la eficiencia.',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...recommendations.map((rec) => _buildRecommendationCard(
              icon: rec['icon'] as IconData,
              color: rec['color'] as Color,
              title: rec['title'] as String,
              description: rec['description'] as String,
            )),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
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
  }
}