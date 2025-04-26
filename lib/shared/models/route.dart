class Route {
  final String id;
  final String name; // nombre
  final String? description; // descripcion
  final String startTime; // horario_inicio (en formato HH:MM)
  final String endTime; // horario_fin (en formato HH:MM)
  final List<String> days; // dias (array de días)
  final String status; // estado

  Route({
    required this.id,
    required this.name,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.status,
  });

  // Factory constructor from JSON
  factory Route.fromJson(Map<String, dynamic> json) {
    print('Creating Route from JSON: $json');
    
    // Convert days from database to List<String>
    List<String> parseDays(dynamic value) {
      if (value is List) {
        return value.map((day) => day.toString()).toList();
      }
      return [];
    }
    
    return Route(
      id: json['id'] as String,
      name: json['nombre'] as String,
      description: json['descripcion'] as String?,
      startTime: json['horario_inicio'] as String,
      endTime: json['horario_fin'] as String,
      days: parseDays(json['dias']),
      status: json['estado'] as String,
    );
  }

  // Method toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'descripcion': description,
      'horario_inicio': startTime,
      'horario_fin': endTime,
      'dias': days,
      'estado': status,
    };
  }

  // CopyWith method to create a copy with changes
  Route copyWith({
    String? id,
    String? name,
    String? description,
    String? startTime,
    String? endTime,
    List<String>? days,
    String? status,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      days: days ?? this.days,
      status: status ?? this.status,
    );
  }
}