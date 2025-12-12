/// Modelo de datos para Cliente
class Cliente {
  final String id;
  final String empresaId;
  final String? userId;
  final String nombre;
  final String email;
  final String? telefono;
  final String? direccion;
  final String? notas;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Cliente({
    required this.id,
    required this.empresaId,
    this.userId,
    required this.nombre,
    required this.email,
    this.telefono,
    this.direccion,
    this.notas,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as String,
      empresaId: map['empresa_id'] as String,
      userId: map['user_id'] as String?,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String?,
      notas: map['notas'] as String?,
      activo: map['activo'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'user_id': userId,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'notas': notas,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Modelo de datos para Producto
class ProductoMultiTenant {
  final String id;
  final String empresaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String? categoria;
  final String? imagenUrl;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductoMultiTenant({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.categoria,
    this.imagenUrl,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductoMultiTenant.fromMap(Map<String, dynamic> map) {
    return ProductoMultiTenant(
      id: map['id'] as String,
      empresaId: map['empresa_id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      precio: _toDouble(map['precio']),
      stock: map['stock'] as int? ?? 0,
      categoria: map['categoria'] as String?,
      imagenUrl: map['imagen_url'] as String?,
      activo: map['activo'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'imagen_url': imagenUrl,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  bool get disponible => activo && stock > 0;
}

/// Estados posibles de un pedido
enum EstadoPedido {
  pendiente,
  confirmado,
  enviado,
  entregado,
  cancelado;

  String get displayName {
    switch (this) {
      case EstadoPedido.pendiente:
        return 'Pendiente';
      case EstadoPedido.confirmado:
        return 'Confirmado';
      case EstadoPedido.enviado:
        return 'Enviado';
      case EstadoPedido.entregado:
        return 'Entregado';
      case EstadoPedido.cancelado:
        return 'Cancelado';
    }
  }
}

/// Modelo de datos para Pedido
class Pedido {
  final String id;
  final String empresaId;
  final String clienteId;
  final String? userId;
  final String numeroPedido;
  final EstadoPedido estado;
  final double total;
  final String? notas;
  final DateTime fechaPedido;
  final DateTime? fechaEntrega;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pedido({
    required this.id,
    required this.empresaId,
    required this.clienteId,
    this.userId,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    this.notas,
    required this.fechaPedido,
    this.fechaEntrega,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'] as String,
      empresaId: map['empresa_id'] as String,
      clienteId: map['cliente_id'] as String,
      userId: map['user_id'] as String?,
      numeroPedido: map['numero_pedido'] as String,
      estado: EstadoPedido.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoPedido.pendiente,
      ),
      total: _toDouble(map['total']),
      notas: map['notas'] as String?,
      fechaPedido: DateTime.parse(map['fecha_pedido'] as String),
      fechaEntrega: map['fecha_entrega'] != null
          ? DateTime.parse(map['fecha_entrega'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'cliente_id': clienteId,
      'user_id': userId,
      'numero_pedido': numeroPedido,
      'estado': estado.name,
      'total': total,
      'notas': notas,
      'fecha_pedido': fechaPedido.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  bool get puedeEditarse => estado == EstadoPedido.pendiente;
  bool get estaCancelado => estado == EstadoPedido.cancelado;
}

/// Modelo de datos para Item de Pedido
class PedidoItem {
  final String id;
  final String pedidoId;
  final String productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final DateTime createdAt;

  const PedidoItem({
    required this.id,
    required this.pedidoId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.createdAt,
  });

  factory PedidoItem.fromMap(Map<String, dynamic> map) {
    return PedidoItem(
      id: map['id'] as String,
      pedidoId: map['pedido_id'] as String,
      productoId: map['producto_id'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: _toDouble(map['precio_unitario']),
      subtotal: _toDouble(map['subtotal']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pedido_id': pedidoId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
