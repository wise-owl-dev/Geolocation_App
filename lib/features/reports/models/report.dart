import 'package:flutter/material.dart';

enum ReportType {
  routePerformance,
  operatorPerformance,
  busUtilization,
  incidents,
  punctuality,
  maintenance,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.routePerformance:
        return 'Rendimiento de Rutas';
      case ReportType.operatorPerformance:
        return 'Rendimiento de Operadores';
      case ReportType.busUtilization:
        return 'Utilización de Autobuses';
      case ReportType.incidents:
        return 'Incidentes';
      case ReportType.punctuality:
        return 'Puntualidad';
      case ReportType.maintenance:
        return 'Mantenimiento';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.routePerformance:
        return Icons.route;
      case ReportType.operatorPerformance:
        return Icons.person;
      case ReportType.busUtilization:
        return Icons.directions_bus;
      case ReportType.incidents:
        return Icons.warning;
      case ReportType.punctuality:
        return Icons.schedule;
      case ReportType.maintenance:
        return Icons.build;
    }
  }

  Color get color {
    switch (this) {
      case ReportType.routePerformance:
        return Colors.blue;
      case ReportType.operatorPerformance:
        return Colors.green;
      case ReportType.busUtilization:
        return Colors.orange;
      case ReportType.incidents:
        return Colors.red;
      case ReportType.punctuality:
        return Colors.purple;
      case ReportType.maintenance:
        return Colors.brown;
    }
  }
}

class ReportData {
  final String id;
  final ReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  ReportData({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.generatedAt,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json['id'] as String,
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.routePerformance,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      data: json['data'] as Map<String, dynamic>,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'data': data,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

// Modelo para métricas de ruta
class RouteMetrics {
  final String routeId;
  final String routeName;
  final int totalTrips;
  final int completedTrips;
  final int cancelledTrips;
  final double averageSpeed;
  final double onTimePercentage;
  final int totalPassengers;
  final double averageOccupancy;

  RouteMetrics({
    required this.routeId,
    required this.routeName,
    required this.totalTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.averageSpeed,
    required this.onTimePercentage,
    required this.totalPassengers,
    required this.averageOccupancy,
  });

  factory RouteMetrics.fromJson(Map<String, dynamic> json) {
    return RouteMetrics(
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      totalTrips: json['total_trips'] as int,
      completedTrips: json['completed_trips'] as int,
      cancelledTrips: json['cancelled_trips'] as int,
      averageSpeed: (json['average_speed'] as num).toDouble(),
      onTimePercentage: (json['on_time_percentage'] as num).toDouble(),
      totalPassengers: json['total_passengers'] as int,
      averageOccupancy: (json['average_occupancy'] as num).toDouble(),
    );
  }
}

// Modelo para métricas de operador
class OperatorMetrics {
  final String operatorId;
  final String operatorName;
  final int totalHours;
  final int totalTrips;
  final int completedTrips;
  final double punctualityRate;
  final int incidentCount;
  final double averageRating;

  OperatorMetrics({
    required this.operatorId,
    required this.operatorName,
    required this.totalHours,
    required this.totalTrips,
    required this.completedTrips,
    required this.punctualityRate,
    required this.incidentCount,
    required this.averageRating,
  });

  factory OperatorMetrics.fromJson(Map<String, dynamic> json) {
    return OperatorMetrics(
      operatorId: json['operator_id'] as String,
      operatorName: json['operator_name'] as String,
      totalHours: json['total_hours'] as int,
      totalTrips: json['total_trips'] as int,
      completedTrips: json['completed_trips'] as int,
      punctualityRate: (json['punctuality_rate'] as num).toDouble(),
      incidentCount: json['incident_count'] as int,
      averageRating: (json['average_rating'] as num).toDouble(),
    );
  }
}