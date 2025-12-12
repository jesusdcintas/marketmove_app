import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/data/models/crm_models.dart';
import 'package:marketmove_app/data/repositories/pedido_repository.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

/// Provider del repositorio de pedidos
final pedidoRepositoryProvider = Provider<PedidoRepository>((ref) {
  return PedidoRepository();
});

/// Provider para listar pedidos de la empresa actual
final pedidosListProvider = FutureProvider<List<Pedido>>((ref) async {
  final repository = ref.watch(pedidoRepositoryProvider);
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  return repository.getAll(empresaId: empresaId);
});

/// Provider para pedidos pendientes
final pedidosPendientesProvider = FutureProvider<List<Pedido>>((ref) async {
  final repository = ref.watch(pedidoRepositoryProvider);
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  return repository.getByEstado(EstadoPedido.pendiente, empresaId: empresaId);
});
