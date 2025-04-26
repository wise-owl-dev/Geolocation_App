class BusStop {
  final String id;
  final String name; // nombre
  final double latitude; // latitud
  final double longitude; // longitud
  final String? address; // direccion
  final String? reference; // referencia
  final String status; // estado

  BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.reference,
    required this.status,
  });

  // Factory constructor from JSON
  factory BusStop.fromJson(Map<String, dynamic> json) {
    print('Creating BusStop from JSON: $json');
    
    // Handle possible different types for latitude and longitude
    double parseDoubleValue(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return BusStop(
      id: json['id'] as String,
      name: json['nombre'] as String,
      latitude: parseDoubleValue(json['latitud']),
      longitude: parseDoubleValue(json['longitud']),
      address: json['direccion'] as String?,
      reference: json['referencia'] as String?,
      status: json['estado'] as String,
    );
  }

  // Method toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'latitud': latitude,
      'longitud': longitude,
      'direccion': address,
      'referencia': reference,
      'estado': status,
    };
  }

  // CopyWith method to create a copy with changes
  BusStop copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? reference,
    String? status,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      reference: reference ?? this.reference,
      status: status ?? this.status,
    );
  }
}