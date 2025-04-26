// lib/shared/models/route_stop.dart
class RouteStop {
  final String id;
  final String routeId;
  final String stopId;
  final int order;
  final int? estimatedTime; // en minutos

  RouteStop({
    required this.id,
    required this.routeId,
    required this.stopId,
    required this.order,
    this.estimatedTime,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'],
      routeId: json['recorrido_id'],
      stopId: json['parada_id'],
      order: json['orden'],
      estimatedTime: json['tiempo_estimado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recorrido_id': routeId,
      'parada_id': stopId,
      'orden': order,
      'tiempo_estimado': estimatedTime,
    };
  }
}