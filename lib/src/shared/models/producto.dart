class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioUnitario;
  final int stock;
  final DateTime? creado;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioUnitario,
    required this.stock,
    this.creado,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precioUnitario: (map['precio_unitario'] ?? map['precio'] ?? 0).toDouble(),
      stock: (map['stock'] ?? map['cantidad'] ?? 0).toInt(),
      creado: _parseDateTime(map['created_at'] ?? map['creado']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'stock': stock,
      'created_at': creado?.toIso8601String(),
    };
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
