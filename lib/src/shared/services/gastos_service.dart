import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gasto.dart';

class GastosService {
  final SupabaseClient _client;

  GastosService() : _client = Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser?.id ?? '';
  void _ensureAuthenticated() {
    if (_currentUserId.isEmpty) {
      throw StateError('No hay una sesión activa para registrar gastos.');
    }
  }

  Future<List<Gasto>> getAll() async {
    final result = await _client
        .from('gastos')
        .select()
        .eq('user_id', _currentUserId)
        .order('fecha', ascending: false);

    final data = result as List<dynamic>?;
    return data
            ?.map((item) => Gasto.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> insert(Gasto gasto) async {
    _ensureAuthenticated();
    final payload = gasto.toMap()
      ..['user_id'] = _currentUserId
      ..['created_at'] = DateTime.now().toIso8601String();

    await _client.from('gastos').insert(payload);
  }

  Future<void> update(Gasto gasto) async {
    final payload = gasto.toMap()
      ..['user_id'] = _currentUserId;

    await _client
        .from('gastos')
        .update(payload)
        .eq('id', gasto.id)
        .eq('user_id', _currentUserId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('gastos')
        .delete()
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }
}
