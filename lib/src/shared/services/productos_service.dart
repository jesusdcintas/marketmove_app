import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';

class ProductosService {
  final SupabaseClient _client;

  ProductosService() : _client = Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser?.id ?? '';
  void _ensureAuthenticated() {
    if (_currentUserId.isEmpty) {
      throw StateError('No hay una sesión activa para registrar productos.');
    }
  }

  Future<List<Producto>> getAll() async {
    final response = await _client
        .from('productos')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>?;
    return data
            ?.map((item) => Producto.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> insert(Producto producto) async {
    _ensureAuthenticated();
    final payload = producto.toMap()
      ..['user_id'] = _currentUserId
      ..['created_at'] = DateTime.now().toIso8601String();

    await _client.from('productos').insert(payload);
  }

  Future<void> update(Producto producto) async {
    final payload = producto.toMap()
      ..['user_id'] = _currentUserId;

    await _client
        .from('productos')
        .update(payload)
        .eq('id', producto.id)
        .eq('user_id', _currentUserId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('productos')
        .delete()
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }
}
