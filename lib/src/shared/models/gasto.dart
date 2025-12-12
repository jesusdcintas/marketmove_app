class Gasto {
  final String id;
  final String userId;
  final String descripcion;
  final double cantidad;
  final DateTime? fecha;
  final DateTime? createdAt;

  const Gasto({
    required this.id,
    required this.userId,
    required this.descripcion,
    required this.cantidad,
    this.fecha,
    this.createdAt,
  });

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      descripcion: map['descripcion'] ?? '',
      cantidad: _toDouble(map['cantidad']),
      fecha: _parseDateTime(map['fecha']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'descripcion': descripcion,
      'cantidad': cantidad,
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

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
