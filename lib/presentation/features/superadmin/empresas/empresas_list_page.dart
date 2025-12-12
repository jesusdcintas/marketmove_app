import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/core/constants/routes.dart';
import 'package:marketmove_app/presentation/providers/empresa_provider.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

class EmpresasListPage extends ConsumerWidget {
  const EmpresasListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empresasAsync = ref.watch(empresasListProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).canPop() 
              ? Navigator.of(context).pop()
              : null,
        ),
        title: const Text('Gestión de Empresas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.go(AppRoutes.superadminUsuarios),
            tooltip: 'Gestionar Usuarios',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authNotifier.signOut(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: empresasAsync.when(
        data: (empresas) {
          if (empresas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay empresas registradas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primera empresa'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: empresas.length,
            itemBuilder: (context, index) {
              final empresa = empresas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: empresa.activa ? Colors.green : Colors.grey,
                        child: Icon(
                          empresa.activa ? Icons.check : Icons.block,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        empresa.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (empresa.nif.isNotEmpty) Text('NIF: ${empresa.nif}'),
                          if (empresa.direccion != null)
                            Text('📍 ${empresa.direccion}'),
                          if (empresa.telefono != null)
                            Text('📞 ${empresa.telefono}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _entrarEmpresa(context, ref, empresa),
                              icon: const Icon(Icons.login, size: 18),
                              label: const Text('Entrar a Empresa'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showEditDialog(context, ref, empresa),
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            onPressed: () => _toggleActive(ref, empresa.id, !empresa.activa),
                            icon: Icon(empresa.activa ? Icons.block : Icons.check),
                            tooltip: empresa.activa ? 'Desactivar' : 'Activar',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(empresasListProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Empresa'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nombreController = TextEditingController();
    final nitController = TextEditingController();
    final direccionController = TextEditingController();
    final telefonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Empresa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nitController,
                decoration: const InputDecoration(
                  labelText: 'NIF',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }

              try {
                final repository = ref.read(empresaRepositoryProvider);
                await repository.create(
                  nombre: nombreController.text,
                  nif: nitController.text.isEmpty ? null : nitController.text,
                  direccion: direccionController.text.isEmpty
                      ? null
                      : direccionController.text,
                  telefono: telefonoController.text.isEmpty
                      ? null
                      : telefonoController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Empresa creada exitosamente')),
                  );
                }

                ref.invalidate(empresasListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _toggleActive(WidgetRef ref, String empresaId, bool newActive) async {
    try {
      final repository = ref.read(empresaRepositoryProvider);
      await repository.toggleActive(empresaId, newActive);
      ref.invalidate(empresasListProvider);
    } catch (e) {
      debugPrint('Error al cambiar estado: $e');
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, empresa) {
    final nombreController = TextEditingController(text: empresa.nombre);
    final nifController = TextEditingController(text: empresa.nif ?? '');
    final direccionController = TextEditingController(text: empresa.direccion ?? '');
    final telefonoController = TextEditingController(text: empresa.telefono ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Empresa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nifController,
                decoration: const InputDecoration(
                  labelText: 'NIF',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }

              try {
                final repository = ref.read(empresaRepositoryProvider);
                await repository.update(
                  empresa.id,
                  {
                    'nombre': nombreController.text,
                    if (nifController.text.isNotEmpty) 'nif': nifController.text,
                    if (direccionController.text.isNotEmpty) 'direccion': direccionController.text,
                    if (telefonoController.text.isNotEmpty) 'telefono': telefonoController.text,
                  },
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Empresa actualizada exitosamente')),
                  );
                }

                ref.invalidate(empresasListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _entrarEmpresa(BuildContext context, WidgetRef ref, empresa) async {
    try {
      final currentProfile = ref.read(currentProfileProvider);
      if (currentProfile == null) return;

      print('🔍 DEBUG INICIO: empresa_id actual: ${currentProfile.empresaId}');
      print('🔍 DEBUG INICIO: empresa_id objetivo: ${empresa.id}');
      
      // Guardar el contexto del messenger para mostrar el loading
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Accediendo a empresa...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Actualizar el perfil del usuario para asignarle esta empresa temporalmente
      final updateResponse = await Supabase.instance.client
          .from('profiles')
          .update({'empresa_id': empresa.id})
          .eq('id', currentProfile.id)
          .select();
      
      print('🔍 DEBUG UPDATE: Respuesta de actualización: $updateResponse');

      // NAVEGAR INMEDIATAMENTE antes de que refreshProfile invalide el contexto
      print('🔍 DEBUG: Navegando ANTES de refreshProfile...');
      if (context.mounted) {
        context.go(AppRoutes.adminDashboard);
        print('🔍 DEBUG: Navegación ejecutada');
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Accediendo a ${empresa.nombre} como SUPERADMIN'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('🔍 DEBUG FINAL: Navegación completada (SIN refreshProfile para evitar redirect)');
      
    } catch (e, stackTrace) {
      print('🔍 DEBUG ERROR: $e');
      print('🔍 DEBUG STACK: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al acceder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
