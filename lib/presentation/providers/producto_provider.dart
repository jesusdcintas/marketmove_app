import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/data/models/crm_models.dart';
import 'package:marketmove_app/data/repositories/producto_repository.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

/// Provider del repositorio de productos
final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return ProductoRepository();
});

/// Provider para listar productos de la empresa actual
final productosListProvider = FutureProvider<List<ProductoMultiTenant>>((ref) async {
  final repository = ref.watch(productoRepositoryProvider);
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  return repository.getAll(empresaId: empresaId);
});

/// Provider para productos disponibles (stock > 0)
final productosDisponiblesProvider = FutureProvider<List<ProductoMultiTenant>>((ref) async {
  final repository = ref.watch(productoRepositoryProvider);
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  return repository.getDisponibles(empresaId: empresaId);
});
