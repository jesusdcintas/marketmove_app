import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/data/models/crm_models.dart';

/// Repositorio para gestión de productos multi-tenant
class ProductoRepository {
  final _supabase = Supabase.instance.client;

  /// Listar productos de la empresa actual (scoped por RLS)
  Future<List<ProductoMultiTenant>> getAll({String? empresaId}) async {
    var query = _supabase.from('productos').select();

    // Si se proporciona empresaId (SUPERADMIN), filtrar explícitamente
    if (empresaId != null) {
      query = query.eq('empresa_id', empresaId);
    }

    final response = await query.order('nombre');
    return (response as List)
        .map((e) => ProductoMultiTenant.fromMap(e))
        .toList();
  }

  /// Obtener productos disponibles (stock > 0)
  Future<List<ProductoMultiTenant>> getDisponibles({String? empresaId}) async {
    var query = _supabase.from('productos').select().gt('stock', 0);

    if (empresaId != null) {
      query = query.eq('empresa_id', empresaId);
    }

    final response = await query.order('nombre');
    return (response as List)
        .map((e) => ProductoMultiTenant.fromMap(e))
        .toList();
  }

  /// Obtener producto por ID
  Future<ProductoMultiTenant> getById(String id) async {
    final response = await _supabase
        .from('productos')
        .select()
        .eq('id', id)
        .single();

    return ProductoMultiTenant.fromMap(response);
  }

  /// Crear producto (ADMIN, scoped por empresa vía RLS)
  Future<ProductoMultiTenant> create({
    required String empresaId,
    required String nombre,
    required String categoria,
    required double precio,
    required int stock,
  }) async {
    final response = await _supabase
        .from('productos')
        .insert({
          'empresa_id': empresaId,
          'nombre': nombre,
          'categoria': categoria,
          'precio': precio,
          'stock': stock,
        })
        .select()
        .single();

    return ProductoMultiTenant.fromMap(response);
  }

  /// Actualizar producto (ADMIN)
  Future<ProductoMultiTenant> update(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('productos')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return ProductoMultiTenant.fromMap(response);
  }

  /// Actualizar stock (ADMIN)
  Future<void> updateStock(String id, int newStock) async {
    await _supabase
        .from('productos')
        .update({'stock': newStock})
        .eq('id', id);
  }

  /// Eliminar producto (ADMIN)
  Future<void> delete(String id) async {
    await _supabase
        .from('productos')
        .delete()
        .eq('id', id);
  }

  /// Buscar productos por nombre o categoría
  Future<List<ProductoMultiTenant>> search(String query, {String? empresaId}) async {
    var searchQuery = _supabase
        .from('productos')
        .select()
        .or('nombre.ilike.%$query%,categoria.ilike.%$query%');

    if (empresaId != null) {
      searchQuery = searchQuery.eq('empresa_id', empresaId);
    }

    final response = await searchQuery.order('nombre');
    return (response as List)
        .map((e) => ProductoMultiTenant.fromMap(e))
        .toList();
  }
}
