import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_card.dart';
import '../widgets/date_range_selector.dart';
import 'route_performance_report.dart';
import 'operator_performance_report.dart';
import 'bus_utilization_report.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Análisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de rango de fechas
            DateRangeSelector(
              startDate: reportsState.selectedStartDate,
              endDate: reportsState.selectedEndDate,
              onDateRangeChanged: (start, end) {
                ref.read(reportsProvider.notifier).updateDateRange(start, end);
              },
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Reportes Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tarjetas de reportes
            ReportCard(
              type: ReportType.routePerformance,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoutePerformanceReportScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            ReportCard(
              type: ReportType.operatorPerformance,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OperatorPerformanceReportScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            ReportCard(
              type: ReportType.busUtilization,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusUtilizationReportScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
/*
            ReportCard(
              type: ReportType.punctuality,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte de puntualidad próximamente'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            ReportCard(
              type: ReportType.incidents,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte de incidentes próximamente'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            ReportCard(
              type: ReportType.maintenance,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte de mantenimiento próximamente'),
                  ),
                );
              },
            ),
*/
          ],
        ),
      ),
    );
  }
}