import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gasto.dart';

class GastosService {
  final SupabaseClient _client;

  GastosService() : _client = Supabase.instance.client;

  Future<List<Gasto>> getAll() async {
    final response = await _client
        .from('gastos')
        .select()
        .order('fecha', ascending: false)
        .execute();

    final data = response.data as List<dynamic>?;
    return data
            ?.map((item) => Gasto.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> insert(Gasto gasto) async {
    await _client.from('gastos').insert(gasto.toMap()).execute();
  }

  Future<void> update(Gasto gasto) async {
    await _client
        .from('gastos')
        .update(gasto.toMap())
        .eq('id', gasto.id)
        .execute();
  }

  Future<void> delete(String id) async {
    await _client.from('gastos').delete().eq('id', id).execute();
  }
}
