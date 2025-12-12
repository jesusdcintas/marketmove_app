import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/venta.dart';

class VentasService {
  final SupabaseClient _client;

  VentasService() : _client = Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser?.id ?? '';
  void _ensureAuthenticated() {
    if (_currentUserId.isEmpty) {
      throw StateError('No hay una sesión activa para registrar ventas.');
    }
  }

  Future<List<Venta>> getAll() async {
    final response = await _client
        .from('ventas')
        .select()
        .eq('user_id', _currentUserId)
        .order('fecha', ascending: false);

    final data = response as List<dynamic>?;
    return data
            ?.map((item) => Venta.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> insert(Venta venta) async {
    _ensureAuthenticated();
    final payload = venta.toMap()
      ..['user_id'] = _currentUserId
      ..['created_at'] = DateTime.now().toIso8601String();

    await _client.from('ventas').insert(payload);
  }

  Future<void> update(Venta venta) async {
    final payload = venta.toMap()
      ..['user_id'] = _currentUserId;

    await _client
        .from('ventas')
        .update(payload)
        .eq('id', venta.id)
        .eq('user_id', _currentUserId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('ventas')
        .delete()
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }
}
