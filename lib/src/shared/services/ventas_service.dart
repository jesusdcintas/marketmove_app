import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/venta.dart';

class VentasService {
  final SupabaseClient _client;

  VentasService() : _client = Supabase.instance.client;

  Future<List<Venta>> getAll() async {
    final response = await _client
        .from('ventas')
        .select()
        .order('fecha', ascending: false)
        .execute();

    final data = response.data as List<dynamic>?;
    return data
            ?.map((item) => Venta.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> insert(Venta venta) async {
    await _client.from('ventas').insert(venta.toMap()).execute();
  }

  Future<void> update(Venta venta) async {
    await _client
        .from('ventas')
        .update(venta.toMap())
        .eq('id', venta.id)
        .execute();
  }

  Future<void> delete(String id) async {
    await _client.from('ventas').delete().eq('id', id).execute();
  }
}
