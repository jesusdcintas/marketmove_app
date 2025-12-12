import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/data/models/crm_models.dart';
import 'package:marketmove_app/data/repositories/cliente_repository.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

/// Provider del repositorio de clientes
final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return ClienteRepository();
});

/// Provider para listar clientes de la empresa actual
final clientesListProvider = FutureProvider<List<Cliente>>((ref) async {
  final repository = ref.watch(clienteRepositoryProvider);
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  return repository.getAll(empresaId: empresaId);
});
