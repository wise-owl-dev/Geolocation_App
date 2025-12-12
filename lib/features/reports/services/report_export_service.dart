// lib/features/reports/services/report_export_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../models/report.dart';

class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  factory ReportExportService() => _instance;
  ReportExportService._internal();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Cache del logo para no cargarlo múltiples veces
  pw.MemoryImage? _cachedLogo;

  // Cargar logo una sola vez
  Future<pw.MemoryImage?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    
    try {
      final logo = await rootBundle.load('assets/images/logo.png');
      final imageBytes = logo.buffer.asUint8List();
      _cachedLogo = pw.MemoryImage(imageBytes);
      return _cachedLogo;
    } catch (e) {
      print('No se pudo cargar el logo: $e');
      return null;
    }
  }

  // ==================== EXPORTACIÓN A PDF ====================

  Future<String> exportRoutePerformanceToPDF({
    required List<RouteMetrics> metrics,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Logo y Encabezado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Rendimiento de Rutas',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Período: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Generado: ${_dateTimeFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              if (logo != null)
                pw.Image(logo, width: 80, height: 80),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 2, color: PdfColors.blue700),

          pw.SizedBox(height: 20),

          // Resumen General
          pw.Text(
            'Resumen General',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildPdfSummaryRow('Total de Viajes', totalTrips.toString()),
                _buildPdfSummaryRow('Viajes Completados', totalCompleted.toString()),
                _buildPdfSummaryRow('Viajes Cancelados', totalCancelled.toString()),
                _buildPdfSummaryRow('Velocidad Promedio', '${avgSpeed.toStringAsFixed(1)} km/h'),
                _buildPdfSummaryRow('Puntualidad Promedio', '${avgOnTime.toStringAsFixed(1)}%'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Detalle por Ruta
          pw.Text(
            'Detalle por Ruta',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          // Tabla de rutas
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Encabezados
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Ruta', isHeader: true),
                  _buildTableCell('Viajes', isHeader: true),
                  _buildTableCell('Completados', isHeader: true),
                  _buildTableCell('Cancelados', isHeader: true),
                  _buildTableCell('Vel. Prom.', isHeader: true),
                  _buildTableCell('Puntualidad', isHeader: true),
                ],
              ),
              // Datos
              ...metrics.map((metric) => pw.TableRow(
                    children: [
                      _buildTableCell(metric.routeName),
                      _buildTableCell(metric.totalTrips.toString()),
                      _buildTableCell(metric.completedTrips.toString()),
                      _buildTableCell(metric.cancelledTrips.toString()),
                      _buildTableCell('${metric.averageSpeed.toStringAsFixed(1)}'),
                      _buildTableCell('${metric.onTimePercentage.toStringAsFixed(1)}%'),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    return await _savePdf(pdf, 'reporte_rutas_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<String> exportOperatorPerformanceToPDF({
    required List<OperatorMetrics> metrics,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    final totalHours = metrics.fold<int>(0, (sum, m) => sum + m.totalHours);
    final totalTrips = metrics.fold<int>(0, (sum, m) => sum + m.totalTrips);
    final avgPunctuality = metrics.isEmpty
        ? 0.0
        : metrics.fold<double>(0, (sum, m) => sum + m.punctualityRate) / metrics.length;
    final totalIncidents = metrics.fold<int>(0, (sum, m) => sum + m.incidentCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Logo y Encabezado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Rendimiento de Operadores',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Período: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Generado: ${_dateTimeFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              if (logo != null)
                pw.Image(logo, width: 80, height: 80),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 2, color: PdfColors.green700),

          pw.SizedBox(height: 20),

          // Resumen General
          pw.Text(
            'Resumen General',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildPdfSummaryRow('Total Operadores', metrics.length.toString()),
                _buildPdfSummaryRow('Total Horas', totalHours.toString()),
                _buildPdfSummaryRow('Total Viajes', totalTrips.toString()),
                _buildPdfSummaryRow('Puntualidad Promedio', '${avgPunctuality.toStringAsFixed(1)}%'),
                _buildPdfSummaryRow('Total Incidentes', totalIncidents.toString()),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Ranking de Operadores
          pw.Text(
            'Ranking de Operadores',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Operador', isHeader: true),
                  _buildTableCell('Horas', isHeader: true),
                  _buildTableCell('Viajes', isHeader: true),
                  _buildTableCell('Puntualidad', isHeader: true),
                  _buildTableCell('Incidentes', isHeader: true),
                ],
              ),
              ...metrics.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final metric = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell(index.toString()),
                    _buildTableCell(metric.operatorName),
                    _buildTableCell(metric.totalHours.toString()),
                    _buildTableCell(metric.totalTrips.toString()),
                    _buildTableCell('${metric.punctualityRate.toStringAsFixed(1)}%'),
                    _buildTableCell(metric.incidentCount.toString()),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return await _savePdf(pdf, 'reporte_operadores_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<String> exportBusUtilizationToPDF({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    final totalBuses = data['total_buses'] as int;
    final activeBuses = data['active_buses'] as int;
    final utilizationRate = data['utilization_rate'] as double;
    final totalTrips = data['total_trips'] as int;
    final completedTrips = data['completed_trips'] as int;
    final cancelledTrips = data['cancelled_trips'] as int;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Logo y Encabezado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Utilización de Autobuses',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Período: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Generado: ${_dateTimeFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              if (logo != null)
                pw.Image(logo, width: 80, height: 80),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 2, color: PdfColors.orange700),

          pw.SizedBox(height: 20),

          // Tasa de Utilización
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Tasa de Utilización',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${utilizationRate.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      fontSize: 48,
                      fontWeight: pw.FontWeight.bold,
                      color: utilizationRate >= 80 ? PdfColors.green : 
                             utilizationRate >= 60 ? PdfColors.orange : PdfColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // Resumen de Flota
          pw.Text(
            'Resumen de Flota',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildPdfSummaryRow('Total Autobuses', totalBuses.toString()),
                _buildPdfSummaryRow('En Operación', activeBuses.toString()),
                _buildPdfSummaryRow('Inactivos', (totalBuses - activeBuses).toString()),
                _buildPdfSummaryRow('Total Viajes', totalTrips.toString()),
                _buildPdfSummaryRow('Viajes Completados', completedTrips.toString()),
                _buildPdfSummaryRow('Viajes Cancelados', cancelledTrips.toString()),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Eficiencia
          pw.Text(
            'Eficiencia de Viajes',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildPdfProgressRow(
                  'Completados',
                  completedTrips,
                  totalTrips,
                ),
                pw.SizedBox(height: 8),
                _buildPdfProgressRow(
                  'Cancelados',
                  cancelledTrips,
                  totalTrips,
                ),
                pw.SizedBox(height: 8),
                _buildPdfProgressRow(
                  'En curso',
                  totalTrips - completedTrips - cancelledTrips,
                  totalTrips,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return await _savePdf(pdf, 'reporte_utilizacion_${DateTime.now().millisecondsSinceEpoch}');
  }

  // ==================== EXPORTACIÓN A CSV ====================

  Future<String> exportRoutePerformanceToCSV({
    required List<RouteMetrics> metrics,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<List<dynamic>> rows = [
      // Metadata
      ['Reporte de Rendimiento de Rutas'],
      ['Período', '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'],
      ['Generado', _dateTimeFormat.format(DateTime.now())],
      [], // Línea vacía
      // Encabezados
      [
        'Ruta',
        'Total Viajes',
        'Completados',
        'Cancelados',
        'Vel. Promedio (km/h)',
        'Puntualidad (%)',
        'Total Pasajeros',
        'Ocupación Promedio (%)',
      ],
      // Datos
      ...metrics.map((m) => [
            m.routeName,
            m.totalTrips,
            m.completedTrips,
            m.cancelledTrips,
            m.averageSpeed.toStringAsFixed(1),
            m.onTimePercentage.toStringAsFixed(1),
            m.totalPassengers,
            m.averageOccupancy.toStringAsFixed(1),
          ]),
    ];

    return await _saveCsv(rows, 'reporte_rutas_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<String> exportOperatorPerformanceToCSV({
    required List<OperatorMetrics> metrics,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<List<dynamic>> rows = [
      // Metadata
      ['Reporte de Rendimiento de Operadores'],
      ['Período', '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'],
      ['Generado', _dateTimeFormat.format(DateTime.now())],
      [], // Línea vacía
      // Encabezados
      [
        'Posición',
        'Operador',
        'Total Horas',
        'Total Viajes',
        'Completados',
        'Puntualidad (%)',
        'Incidentes',
        'Calificación',
      ],
      // Datos
      ...metrics.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final m = entry.value;
        return [
          index,
          m.operatorName,
          m.totalHours,
          m.totalTrips,
          m.completedTrips,
          m.punctualityRate.toStringAsFixed(1),
          m.incidentCount,
          m.averageRating.toStringAsFixed(1),
        ];
      }),
    ];

    return await _saveCsv(rows, 'reporte_operadores_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<String> exportBusUtilizationToCSV({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final totalBuses = data['total_buses'] as int;
    final activeBuses = data['active_buses'] as int;
    final utilizationRate = data['utilization_rate'] as double;
    final totalTrips = data['total_trips'] as int;
    final completedTrips = data['completed_trips'] as int;
    final cancelledTrips = data['cancelled_trips'] as int;

    final List<List<dynamic>> rows = [
      // Metadata
      ['Reporte de Utilización de Autobuses'],
      ['Período', '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'],
      ['Generado', _dateTimeFormat.format(DateTime.now())],
      [], // Línea vacía
      // Datos
      ['Métrica', 'Valor'],
      ['Total Autobuses', totalBuses],
      ['En Operación', activeBuses],
      ['Inactivos', totalBuses - activeBuses],
      ['Tasa de Utilización (%)', utilizationRate.toStringAsFixed(1)],
      ['Total Viajes', totalTrips],
      ['Viajes Completados', completedTrips],
      ['Viajes Cancelados', cancelledTrips],
      ['Viajes en Curso', totalTrips - completedTrips - cancelledTrips],
    ];

    return await _saveCsv(rows, 'reporte_utilizacion_${DateTime.now().millisecondsSinceEpoch}');
  }

  // ==================== MÉTODOS AUXILIARES ====================

  pw.Widget _buildPdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfProgressRow(String label, int value, int total) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
            pw.Text(
              '$value de $total (${percentage.toStringAsFixed(1)}%)',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<String> _savePdf(pw.Document pdf, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }

  Future<String> _saveCsv(List<List<dynamic>> rows, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.csv');
      
      // Configuración personalizada del CSV
      String csv = const ListToCsvConverter(
        fieldDelimiter: ';',        // Usar punto y coma (compatible con Excel español)
        textDelimiter: '"',         // Delimitador de texto
        textEndDelimiter: '"',      // Delimitador de cierre
        eol: '\n',                  // Fin de línea
      ).convert(rows);
      
      await file.writeAsString(csv);
      
      return file.path;
    } catch (e) {
      throw Exception('Error al guardar CSV: $e');
    }
  }

  // Compartir archivo
  Future<void> shareFile(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: 'Reporte',
        text: 'Reporte generado desde la aplicación',
      );
    } catch (e) {
      throw Exception('Error al compartir archivo: $e');
    }
  }
}