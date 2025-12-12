class Venta {
  final String id;
  final String userId;
  final String productoId;
  final int unidades;
  final double total;
  final DateTime? fecha;
  final DateTime? createdAt;

  const Venta({
    required this.id,
    required this.userId,
    required this.productoId,
    required this.unidades,
    required this.total,
    this.fecha,
    this.createdAt,
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      productoId: map['producto_id']?.toString() ?? '',
      unidades: _toInt(map['unidades'] ?? map['cantidad']),
      total: _toDouble(map['total']),
      fecha: _parseDateTime(map['fecha']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'producto_id': productoId,
      'unidades': unidades,
      'total': total,
      'fecha': fecha?.toIso8601String(),
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
