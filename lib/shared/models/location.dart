// lib/shared/models/location.dart
import 'dart:convert';

class Location {
  final String id;
  final String assignmentId;
  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime timestamp;
  final String? currentStopId;
  final String? nextStopId;

  Location({
    required this.id,
    required this.assignmentId,
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.timestamp,
    this.currentStopId,
    this.nextStopId,
  });

  factory Location.fromRawJson(String str) => Location.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json["id"],
    assignmentId: json["asignacion_id"],
    latitude: _parseDouble(json["latitud"]),
    longitude: _parseDouble(json["longitud"]),
    speed: json["velocidad"] != null ? _parseDouble(json["velocidad"]) : null,
    timestamp: DateTime.parse(json["timestamp"]),
    currentStopId: json["parada_actual_id"],
    nextStopId: json["proxima_parada_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "asignacion_id": assignmentId,
    "latitud": latitude,
    "longitud": longitude,
    "velocidad": speed,
    "timestamp": timestamp.toIso8601String(),
    "parada_actual_id": currentStopId,
    "proxima_parada_id": nextStopId,
  };

  // Helper method to parse potentially varying numeric formats
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Create a new instance with optional updated fields
  Location copyWith({
    String? id,
    String? assignmentId,
    double? latitude,
    double? longitude,
    double? speed,
    DateTime? timestamp,
    String? currentStopId,
    String? nextStopId,
  }) {
    return Location(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      currentStopId: currentStopId ?? this.currentStopId,
      nextStopId: nextStopId ?? this.nextStopId,
    );
  }
}