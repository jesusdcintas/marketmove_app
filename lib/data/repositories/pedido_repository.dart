import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/data/models/crm_models.dart';

/// Repositorio para gestión de pedidos multi-tenant
class PedidoRepository {
  final _supabase = Supabase.instance.client;

  /// Listar pedidos de la empresa actual (scoped por RLS)
  Future<List<Pedido>> getAll({String? empresaId, String? clienteId}) async {
    var query = _supabase
        .from('pedidos')
        .select('*, clientes(*), pedidos_items(*, productos(*))');

    if (empresaId != null) {
      query = query.eq('empresa_id', empresaId);
    }

    if (clienteId != null) {
      query = query.eq('cliente_id', clienteId);
    }

    final response = await query.order('fecha_pedido', ascending: false);
    return (response as List)
        .map((e) => Pedido.fromMap(e))
        .toList();
  }

  /// Obtener pedidos por estado
  Future<List<Pedido>> getByEstado(EstadoPedido estado, {String? empresaId}) async {
    var query = _supabase
        .from('pedidos')
        .select('*, clientes(*), pedidos_items(*, productos(*))')
        .eq('estado', estado.name);

    if (empresaId != null) {
      query = query.eq('empresa_id', empresaId);
    }

    final response = await query.order('fecha_pedido', ascending: false);
    return (response as List)
        .map((e) => Pedido.fromMap(e))
        .toList();
  }

  /// Obtener pedido por ID con todos los items
  Future<Pedido> getById(String id) async {
    final response = await _supabase
        .from('pedidos')
        .select('*, clientes(*), pedidos_items(*, productos(*))')
        .eq('id', id)
        .single();

    return Pedido.fromMap(response);
  }

  /// Crear pedido (ADMIN o CLIENTE)
  Future<Pedido> create({
    required String empresaId,
    required String clienteId,
    required List<Map<String, dynamic>> items, // [{producto_id, cantidad, precio_unitario}]
  }) async {
    // Calcular total
    double total = 0;
    for (var item in items) {
      total += (item['cantidad'] as int) * (item['precio_unitario'] as double);
    }

    // Generar número de pedido único
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final numeroPedido = 'PED-$timestamp';

    // Crear pedido
    final pedidoResponse = await _supabase
        .from('pedidos')
        .insert({
          'empresa_id': empresaId,
          'cliente_id': clienteId,
          'numero_pedido': numeroPedido,
          'total': total,
          'estado': EstadoPedido.pendiente.name,
        })
        .select()
        .single();

    final pedidoId = pedidoResponse['id'];

    // Crear items del pedido
    final itemsWithPedidoId = items.map((item) {
      return {
        'pedido_id': pedidoId,
        'producto_id': item['producto_id'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
      };
    }).toList();

    await _supabase.from('pedidos_items').insert(itemsWithPedidoId);

    // Retornar pedido completo
    return getById(pedidoId);
  }

  /// Actualizar estado del pedido (ADMIN)
  Future<Pedido> updateEstado(String id, EstadoPedido nuevoEstado) async {
    final response = await _supabase
        .from('pedidos')
        .update({'estado': nuevoEstado.name})
        .eq('id', id)
        .select()
        .single();

    return Pedido.fromMap(response);
  }

  /// Cancelar pedido (ADMIN o CLIENTE si está PENDIENTE)
  Future<Pedido> cancelar(String id) async {
    return updateEstado(id, EstadoPedido.cancelado);
  }

  /// Marcar como entregado (ADMIN)
  Future<Pedido> marcarEntregado(String id) async {
    return updateEstado(id, EstadoPedido.entregado);
  }

  /// Eliminar pedido (solo ADMIN, no recomendado)
  Future<void> delete(String id) async {
    // Primero eliminar items
    await _supabase
        .from('pedidos_items')
        .delete()
        .eq('pedido_id', id);

    // Luego eliminar pedido
    await _supabase
        .from('pedidos')
        .delete()
        .eq('id', id);
  }

  /// Obtener estadísticas de pedidos por empresa
  Future<Map<String, dynamic>> getEstadisticas(String empresaId) async {
    final response = await _supabase
        .from('pedidos')
        .select('estado, total')
        .eq('empresa_id', empresaId);

    final pedidos = response as List;

    // Calcular estadísticas
    int totalPedidos = pedidos.length;
    double totalVentas = 0;
    Map<String, int> porEstado = {};

    for (var p in pedidos) {
      totalVentas += (p['total'] as num).toDouble();
      final estado = p['estado'] as String;
      porEstado[estado] = (porEstado[estado] ?? 0) + 1;
    }

    return {
      'total_pedidos': totalPedidos,
      'total_ventas': totalVentas,
      'por_estado': porEstado,
    };
  }
}
