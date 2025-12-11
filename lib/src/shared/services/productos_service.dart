import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';

class ProductosService {
  final SupabaseClient _client;

  ProductosService() : _client = Supabase.instance.client;

  Future<List<Producto>> getAll() async {
    final response = await _client
      .from('productos')
      .select()
      .order('created_at', ascending: false)
      .execute();

    final data = response.data as List<dynamic>?;
    return data
            ?.map((item) => Producto.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> insert(Producto producto) async {
    await _client.from('productos').insert(producto.toMap()).execute();
  }

  Future<void> update(Producto producto) async {
    await _client
        .from('productos')
        .update(producto.toMap())
        .eq('id', producto.id)
        .execute();
  }

  Future<void> delete(String id) async {
    await _client.from('productos').delete().eq('id', id).execute();
  }
}
