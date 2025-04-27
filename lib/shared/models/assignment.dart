// lib/shared/models/assignment.dart
import 'package:flutter/material.dart';

enum AssignmentStatus {
  programada,
  en_curso,
  completada,
  cancelada
}

extension AssignmentStatusExtension on AssignmentStatus {
  String get name {
    switch (this) {
      case AssignmentStatus.programada: return 'programada';
      case AssignmentStatus.en_curso: return 'en_curso';
      case AssignmentStatus.completada: return 'completada';
      case AssignmentStatus.cancelada: return 'cancelada';
    }
  }
  
  String get displayName {
    switch (this) {
      case AssignmentStatus.programada: return 'Programada';
      case AssignmentStatus.en_curso: return 'En Curso';
      case AssignmentStatus.completada: return 'Completada';
      case AssignmentStatus.cancelada: return 'Cancelada';
    }
  }
  
  Color get color {
    switch (this) {
      case AssignmentStatus.programada: return Colors.blue;
      case AssignmentStatus.en_curso: return Colors.green;
      case AssignmentStatus.completada: return Colors.purple;
      case AssignmentStatus.cancelada: return Colors.red;
    }
  }
  
  static AssignmentStatus fromString(String value) {
    return AssignmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssignmentStatus.programada,
    );
  }
}

class Assignment {
  final String id;
  final String operatorId;
  final String busId;
  final String routeId;
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final AssignmentStatus status;
  
  // Información adicional (se puede cargar bajo demanda)
  final String? operatorName;
  final String? busNumber;
  final String? routeName;

  Assignment({
    required this.id,
    required this.operatorId,
    required this.busId,
    required this.routeId,
    required this.startDate,
    this.endDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.operatorName,
    this.busNumber,
    this.routeName,
  });

  factory Assignment.fromJson(Map<String, dynamic> json, {
    String? operatorName,
    String? busNumber,
    String? routeName,
  }) {
    // Función para convertir string de hora a TimeOfDay
    TimeOfDay parseTimeString(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1].split(':')[0]),
      );
    }

    return Assignment(
      id: json['id'],
      operatorId: json['operador_id'],
      busId: json['autobus_id'],
      routeId: json['recorrido_id'],
      startDate: DateTime.parse(json['fecha_inicio']),
      endDate: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      startTime: parseTimeString(json['hora_inicio']),
      endTime: parseTimeString(json['hora_fin']),
      status: AssignmentStatusExtension.fromString(json['estado']),
      operatorName: operatorName,
      busNumber: busNumber,
      routeName: routeName,
    );
  }

  Map<String, dynamic> toJson() {
    // Función para formatear TimeOfDay a string
    String formatTimeOfDay(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    return {
      'id': id,
      'operador_id': operatorId,
      'autobus_id': busId,
      'recorrido_id': routeId,
      'fecha_inicio': startDate.toIso8601String().split('T')[0],
      'fecha_fin': endDate?.toIso8601String().split('T')[0],
      'hora_inicio': formatTimeOfDay(startTime),
      'hora_fin': formatTimeOfDay(endTime),
      'estado': status.name,
    };
  }
}