class Venta {
  final String id;
  final String productoId;
  final int cantidad;
  final double total;
  final DateTime? fecha;
  final String cliente;
  final String? notas;

  Venta({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.total,
    this.fecha,
    required this.cliente,
    this.notas,
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id']?.toString() ?? '',
      productoId: map['producto_id']?.toString() ?? '',
      cantidad: (map['cantidad'] ?? 0).toInt(),
      total: (map['total'] ?? 0).toDouble(),
      fecha: _parseDateTime(map['fecha'] ?? map['created_at']),
      cliente: map['cliente'] ?? '',
      notas: map['notas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'cantidad': cantidad,
      'total': total,
      'fecha': fecha?.toIso8601String(),
      'cliente': cliente,
      if (notas != null) 'notas': notas,
    };
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
