import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/data/models/profile.dart';
import 'package:marketmove_app/data/repositories/empresa_repository.dart';

/// Provider del repositorio de empresas
final empresaRepositoryProvider = Provider<EmpresaRepository>((ref) {
  return EmpresaRepository();
});

/// Provider para listar todas las empresas (solo SUPERADMIN)
final empresasListProvider = FutureProvider<List<Empresa>>((ref) async {
  final repository = ref.watch(empresaRepositoryProvider);
  return repository.getAll();
});

/// Provider para crear empresa
final createEmpresaProvider = Provider<EmpresaRepository>((ref) {
  return ref.watch(empresaRepositoryProvider);
});
