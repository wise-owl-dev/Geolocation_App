// lib/features/reports/screens/operator_performance_report.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class OperatorPerformanceReportScreen extends ConsumerStatefulWidget {
  const OperatorPerformanceReportScreen({super.key});

  @override
  ConsumerState<OperatorPerformanceReportScreen> createState() =>
      _OperatorPerformanceReportScreenState();
}

class _OperatorPerformanceReportScreenState
    extends ConsumerState<OperatorPerformanceReportScreen> {
  String _sortBy = 'trips'; // trips, hours, punctuality
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).generateOperatorPerformanceReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendimiento de Operadores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar por',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = false;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'trips',
                child: Text('Viajes realizados'),
              ),
              const PopupMenuItem(
                value: 'hours',
                child: Text('Horas trabajadas'),
              ),
              const PopupMenuItem(
                value: 'punctuality',
                child: Text('Puntualidad'),
              ),
              const PopupMenuItem(
                value: 'incidents',
                child: Text('Incidentes'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.read(reportsProvider.notifier).generateOperatorPerformanceReport();
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
              : reportsState.operatorMetrics.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(_getSortedMetrics(reportsState.operatorMetrics)),
    );
  }

  List<OperatorMetrics> _getSortedMetrics(List<OperatorMetrics> metrics) {
    final sorted = List<OperatorMetrics>.from(metrics);
    
    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'trips':
          comparison = a.totalTrips.compareTo(b.totalTrips);
          break;
        case 'hours':
          comparison = a.totalHours.compareTo(b.totalHours);
          break;
        case 'punctuality':
          comparison = a.punctualityRate.compareTo(b.punctualityRate);
          break;
        case 'incidents':
          comparison = a.incidentCount.compareTo(b.incidentCount);
          break;
        default:
          comparison = 0;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sorted;
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
                ref.read(reportsProvider.notifier).generateOperatorPerformanceReport();
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

  Widget _buildContent(List<OperatorMetrics> metrics) {
    // Calcular totales
    final totalHours = metrics.fold<int>(0, (sum, m) => sum + m.totalHours);
    final totalTrips = metrics.fold<int>(0, (sum, m) => sum + m.totalTrips);
    final avgPunctuality = metrics.isEmpty
        ? 0.0
        : metrics.fold<double>(0, (sum, m) => sum + m.punctualityRate) / metrics.length;
    final totalIncidents = metrics.fold<int>(0, (sum, m) => sum + m.incidentCount);

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
            totalOperators: metrics.length,
            totalHours: totalHours,
            totalTrips: totalTrips,
            avgPunctuality: avgPunctuality,
            totalIncidents: totalIncidents,
          ),

          const SizedBox(height: 24),

          // Ranking de operadores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ranking de Operadores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSortLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top 3 podio
          if (metrics.length >= 3) _buildPodium(metrics.take(3).toList()),

          const SizedBox(height: 16),

          // Lista completa de operadores
          ...metrics.asMap().entries.map((entry) {
            final index = entry.key;
            final metric = entry.value;
            return _buildOperatorCard(metric, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'trips':
        return 'Por viajes';
      case 'hours':
        return 'Por horas';
      case 'punctuality':
        return 'Por puntualidad';
      case 'incidents':
        return 'Por incidentes';
      default:
        return '';
    }
  }

  Widget _buildSummaryCards({
    required int totalOperators,
    required int totalHours,
    required int totalTrips,
    required double avgPunctuality,
    required int totalIncidents,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.person,
                title: 'Operadores',
                value: totalOperators.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.access_time,
                title: 'Total Horas',
                value: totalHours.toString(),
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
                icon: Icons.route,
                title: 'Total Viajes',
                value: totalTrips.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.warning,
                title: 'Incidentes',
                value: totalIncidents.toString(),
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          icon: Icons.schedule,
          title: 'Puntualidad Promedio',
          value: '${avgPunctuality.toStringAsFixed(1)}%',
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

  Widget _buildPodium(List<OperatorMetrics> topThree) {
    return Container(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Segundo lugar
          if (topThree.length > 1)
            Expanded(
              child: _buildPodiumPlace(topThree[1], 2, 120, Colors.grey),
            ),
          // Primer lugar
          Expanded(
            child: _buildPodiumPlace(topThree[0], 1, 150, Colors.amber),
          ),
          // Tercer lugar
          if (topThree.length > 2)
            Expanded(
              child: _buildPodiumPlace(topThree[2], 3, 100, Colors.brown),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    OperatorMetrics metric,
    int place,
    double height,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            '$place°',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getOperatorShortName(metric.operatorName),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              _getPodiumValue(metric),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  String _getOperatorShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]}\n${parts[1]}';
    }
    return fullName;
  }

  String _getPodiumValue(OperatorMetrics metric) {
    switch (_sortBy) {
      case 'trips':
        return '${metric.totalTrips}\nviajes';
      case 'hours':
        return '${metric.totalHours}\nhoras';
      case 'punctuality':
        return '${metric.punctualityRate.toStringAsFixed(1)}%\npuntual';
      case 'incidents':
        return '${metric.incidentCount}\nincidentes';
      default:
        return '';
    }
  }

  Widget _buildOperatorCard(OperatorMetrics metric, int position) {
    final completionRate = metric.totalTrips > 0
        ? (metric.completedTrips / metric.totalTrips * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: position <= 3 ? 3 : 1,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getPositionColor(position),
          child: Text(
            '$position',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          metric.operatorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${metric.totalTrips} viajes • ${metric.totalHours} horas',
        ),
        trailing: _buildPerformanceBadge(metric.punctualityRate),
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
                  'Horas Trabajadas',
                  '${metric.totalHours} hrs',
                  Icons.access_time,
                ),
                const Divider(),
                _buildMetricRow(
                  'Puntualidad',
                  '${metric.punctualityRate.toStringAsFixed(1)}%',
                  Icons.schedule,
                  valueColor: metric.punctualityRate >= 80
                      ? Colors.green
                      : metric.punctualityRate >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
                const Divider(),
                _buildMetricRow(
                  'Incidentes',
                  metric.incidentCount.toString(),
                  Icons.warning,
                  valueColor: metric.incidentCount > 5
                      ? Colors.red
                      : metric.incidentCount > 2
                          ? Colors.orange
                          : Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    if (position == 1) return Colors.amber;
    if (position == 2) return Colors.grey;
    if (position == 3) return Colors.brown;
    return Colors.blue;
  }

  Widget _buildPerformanceBadge(double punctuality) {
    Color color;
    String label;

    if (punctuality >= 90) {
      color = Colors.green;
      label = 'Excelente';
    } else if (punctuality >= 80) {
      color = Colors.lightGreen;
      label = 'Muy Bien';
    } else if (punctuality >= 70) {
      color = Colors.orange;
      label = 'Bien';
    } else if (punctuality >= 60) {
      color = Colors.deepOrange;
      label = 'Regular';
    } else {
      color = Colors.red;
      label = 'Bajo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
  }
}