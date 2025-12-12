// lib/features/reports/providers/reports_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportsState {
  final bool isLoading;
  final String? error;
  final List<RouteMetrics> routeMetrics;
  final List<OperatorMetrics> operatorMetrics;
  final Map<String, dynamic>? busUtilization;
  final Map<String, dynamic>? generalStats;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

  ReportsState({
    this.isLoading = false,
    this.error,
    this.routeMetrics = const [],
    this.operatorMetrics = const [],
    this.busUtilization,
    this.generalStats,
    this.selectedStartDate,
    this.selectedEndDate,
  });

  ReportsState copyWith({
    bool? isLoading,
    String? error,
    List<RouteMetrics>? routeMetrics,
    List<OperatorMetrics>? operatorMetrics,
    Map<String, dynamic>? busUtilization,
    Map<String, dynamic>? generalStats,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      routeMetrics: routeMetrics ?? this.routeMetrics,
      operatorMetrics: operatorMetrics ?? this.operatorMetrics,
      busUtilization: busUtilization ?? this.busUtilization,
      generalStats: generalStats ?? this.generalStats,
      selectedStartDate: selectedStartDate ?? this.selectedStartDate,
      selectedEndDate: selectedEndDate ?? this.selectedEndDate,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final _supabase = Supabase.instance.client;

  ReportsNotifier() : super(ReportsState()) {
    final now = DateTime.now();
    state = state.copyWith(
      selectedStartDate: DateTime(now.year, now.month, 1),
      selectedEndDate: DateTime(now.year, now.month + 1, 0),
    );
  }

  void updateDateRange(DateTime startDate, DateTime endDate) {
    state = state.copyWith(
      selectedStartDate: startDate,
      selectedEndDate: endDate,
    );
  }

  // Usar función RPC para rendimiento de rutas
  Future<void> generateRoutePerformanceReport() async {
    if (state.selectedStartDate == null || state.selectedEndDate == null) {
      state = state.copyWith(error: 'Por favor seleccione un rango de fechas');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _supabase.rpc(
        'get_reporte_rendimiento_rutas',
        params: {
          'p_fecha_inicio': state.selectedStartDate!.toIso8601String().split('T')[0],
          'p_fecha_fin': state.selectedEndDate!.toIso8601String().split('T')[0],
        },
      );

      final List<RouteMetrics> metrics = (result as List)
          .map((item) => RouteMetrics.fromJson(item))
          .toList();

      state = state.copyWith(
        routeMetrics: metrics,
        isLoading: false,
      );
    } catch (e) {
      print('Error generating route performance report: $e');
      state = state.copyWith(
        error: 'Error al generar el reporte: $e',
        isLoading: false,
      );
    }
  }

  // Usar función RPC para rendimiento de operadores
  Future<void> generateOperatorPerformanceReport() async {
    if (state.selectedStartDate == null || state.selectedEndDate == null) {
      state = state.copyWith(error: 'Por favor seleccione un rango de fechas');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _supabase.rpc(
        'get_reporte_rendimiento_operadores',
        params: {
          'p_fecha_inicio': state.selectedStartDate!.toIso8601String().split('T')[0],
          'p_fecha_fin': state.selectedEndDate!.toIso8601String().split('T')[0],
        },
      );

      final List<OperatorMetrics> metrics = (result as List)
          .map((item) => OperatorMetrics.fromJson(item))
          .toList();

      state = state.copyWith(
        operatorMetrics: metrics,
        isLoading: false,
      );
    } catch (e) {
      print('Error generating operator performance report: $e');
      state = state.copyWith(
        error: 'Error al generar el reporte: $e',
        isLoading: false,
      );
    }
  }

  // Usar función RPC para utilización de autobuses
  Future<void> generateBusUtilizationReport() async {
    if (state.selectedStartDate == null || state.selectedEndDate == null) {
      state = state.copyWith(error: 'Por favor seleccione un rango de fechas');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _supabase.rpc(
        'get_reporte_utilizacion_autobuses',
        params: {
          'p_fecha_inicio': state.selectedStartDate!.toIso8601String().split('T')[0],
          'p_fecha_fin': state.selectedEndDate!.toIso8601String().split('T')[0],
        },
      );

      // La función retorna una lista con un solo elemento
      final data = (result as List).isNotEmpty ? result[0] : {};

      state = state.copyWith(
        busUtilization: data,
        isLoading: false,
      );
    } catch (e) {
      print('Error generating bus utilization report: $e');
      state = state.copyWith(
        error: 'Error al generar el reporte: $e',
        isLoading: false,
      );
    }
  }

  // Obtener estadísticas generales
  Future<void> loadGeneralStats() async {
    if (state.selectedStartDate == null || state.selectedEndDate == null) {
      return;
    }

    try {
      final result = await _supabase.rpc(
        'get_estadisticas_generales',
        params: {
          'p_fecha_inicio': state.selectedStartDate!.toIso8601String().split('T')[0],
          'p_fecha_fin': state.selectedEndDate!.toIso8601String().split('T')[0],
        },
      );

      final data = (result as List).isNotEmpty ? result[0] : {};

      state = state.copyWith(generalStats: data);
    } catch (e) {
      print('Error loading general stats: $e');
    }
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier();
});