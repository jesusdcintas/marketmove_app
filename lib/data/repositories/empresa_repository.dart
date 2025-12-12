import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/data/models/profile.dart';

/// Repositorio para gestión de empresas (solo SUPERADMIN)
class EmpresaRepository {
  final _supabase = Supabase.instance.client;

  /// Listar todas las empresas (solo SUPERADMIN)
  Future<List<Empresa>> getAll() async {
    final response = await _supabase
        .from('empresas')
        .select()
        .order('nombre');

    return (response as List)
        .map((e) => Empresa.fromMap(e))
        .toList();
  }

  /// Obtener empresa por ID
  Future<Empresa> getById(String id) async {
    final response = await _supabase
        .from('empresas')
        .select()
        .eq('id', id)
        .single();

    return Empresa.fromMap(response);
  }

  /// Crear nueva empresa (solo SUPERADMIN)
  Future<Empresa> create({
    required String nombre,
    String? nif,
    String? direccion,
    String? telefono,
  }) async {
    final response = await _supabase
        .from('empresas')
        .insert({
          'nombre': nombre,
          'nif': nif,
          'direccion': direccion,
          'telefono': telefono,
          'activa': true,
        })
        .select()
        .single();

    return Empresa.fromMap(response);
  }

  /// Actualizar empresa (solo SUPERADMIN)
  Future<Empresa> update(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('empresas')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Empresa.fromMap(response);
  }

  /// Activar/desactivar empresa (solo SUPERADMIN)
  Future<void> toggleActive(String id, bool activa) async {
    await _supabase
        .from('empresas')
        .update({'activa': activa})
        .eq('id', id);
  }

  /// Eliminar empresa (solo SUPERADMIN, no recomendado en producción)
  Future<void> delete(String id) async {
    await _supabase
        .from('empresas')
        .delete()
        .eq('id', id);
  }
}
