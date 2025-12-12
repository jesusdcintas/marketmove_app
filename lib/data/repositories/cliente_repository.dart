import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/data/models/crm_models.dart';

/// Repositorio para gestión de clientes multi-tenant
class ClienteRepository {
  final _supabase = Supabase.instance.client;

  /// Listar clientes de la empresa actual (scoped por RLS)
  Future<List<Cliente>> getAll({String? empresaId}) async {
    var query = _supabase.from('clientes').select();

    if (empresaId != null) {
      query = query.eq('empresa_id', empresaId);
    }

    final response = await query.order('nombre');
    return (response as List)
        .map((e) => Cliente.fromMap(e))
        .toList();
  }

  /// Obtener cliente por ID
  Future<Cliente> getById(String id) async {
    final response = await _supabase
        .from('clientes')
        .select()
        .eq('id', id)
        .single();

    return Cliente.fromMap(response);
  }

  /// Crear cliente (ADMIN)
  Future<Cliente> create({
    required String empresaId,
    required String nombre,
    required String email,
    String? telefono,
    String? direccion,
  }) async {
    final response = await _supabase
        .from('clientes')
        .insert({
          'empresa_id': empresaId,
          'nombre': nombre,
          'email': email,
          'telefono': telefono,
          'direccion': direccion,
        })
        .select()
        .single();

    return Cliente.fromMap(response);
  }

  /// Actualizar cliente (ADMIN)
  Future<Cliente> update(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('clientes')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Cliente.fromMap(response);
  }

  /// Eliminar cliente (ADMIN)
  Future<void> delete(String id) async {
    await _supabase
        .from('clientes')
        .delete()
        .eq('id', id);
  }

  /// Buscar clientes por nombre o email
  Future<List<Cliente>> search(String query, {String? empresaId}) async {
    var searchQuery = _supabase
        .from('clientes')
        .select()
        .or('nombre.ilike.%$query%,email.ilike.%$query%');

    if (empresaId != null) {
      searchQuery = searchQuery.eq('empresa_id', empresaId);
    }

    final response = await searchQuery.order('nombre');
    return (response as List)
        .map((e) => Cliente.fromMap(e))
        .toList();
  }

  /// Obtener clientes activos (con pedidos recientes)
  Future<List<Cliente>> getActivos({String? empresaId}) async {
    // Aquí se puede mejorar con un join a pedidos
    // Por ahora devuelve todos, pero se puede filtrar por fecha de último pedido
    return getAll(empresaId: empresaId);
  }
}
