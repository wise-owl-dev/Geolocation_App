class Bus {
  final String id;
  final String busNumber; // numero_unidad
  final String licensePlate; // placa
  final int capacity; // capacidad
  final String model; // modelo
  final String brand; // marca
  final int year; // año
  final String status; // estado

  Bus({
    required this.id,
    required this.busNumber,
    required this.licensePlate,
    required this.capacity,
    required this.model,
    required this.brand,
    required this.year,
    required this.status,
  });

  // Factory constructor desde JSON
  factory Bus.fromJson(Map<String, dynamic> json) {
    print('Creando Bus desde JSON: $json');
    
    // Manejar posibles tipos diferentes para capacidad y año
    int parseIntValue(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return Bus(
      id: json['id'] as String,
      busNumber: json['numero_unidad'] as String,
      licensePlate: json['placa'] as String,
      capacity: parseIntValue(json['capacidad']),
      model: json['modelo'] as String,
      brand: json['marca'] as String,
      year: parseIntValue(json['año']),
      status: json['estado'] as String,
    );
  }

  // Método toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_unidad': busNumber,
      'placa': licensePlate,
      'capacidad': capacity,
      'modelo': model,
      'marca': brand,
      'año': year,
      'estado': status,
    };
  }

  // Método copyWith para crear una copia con cambios
  Bus copyWith({
    String? id,
    String? busNumber,
    String? licensePlate,
    int? capacity,
    String? model,
    String? brand,
    int? year,
    String? status,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      capacity: capacity ?? this.capacity,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      year: year ?? this.year,
      status: status ?? this.status,
    );
  }
}