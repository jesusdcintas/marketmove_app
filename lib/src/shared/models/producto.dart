class Producto {
  final String id;
  final String userId;
  final String nombre;
  final double precio;
  final int stock;
  final DateTime? createdAt;

  const Producto({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.createdAt,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      nombre: map['nombre'] ?? '',
      precio: _toDouble(map['precio']),
      stock: _toInt(map['stock']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0; 
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
