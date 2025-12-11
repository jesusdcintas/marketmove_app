class Gasto {
  final String id;
  final String descripcion;
  final double monto;
  final String categoria;
  final DateTime? fecha;

  Gasto({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.categoria,
    this.fecha,
  });

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id']?.toString() ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] ?? map['cantidad'] ?? 0).toDouble(),
      categoria: map['categoria'] ?? 'general',
      fecha: _parseDateTime(map['fecha'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'categoria': categoria,
      'fecha': fecha?.toIso8601String(),
    };
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
