import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/presentation/providers/cliente_provider.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

class ClientesAdminPage extends ConsumerWidget {
  const ClientesAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesListProvider);
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gestión de Clientes'),
      ),
      body: clientesAsync.when(
        data: (clientes) {
          // Filtrar por empresa del ADMIN
          final clientesEmpresa = profile?.empresaId != null
              ? clientes.where((c) => c.empresaId == profile!.empresaId).toList()
              : clientes;

          if (clientesEmpresa.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay clientes registrados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context, ref, profile?.empresaId),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer cliente'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clientesEmpresa.length,
            itemBuilder: (context, index) {
              final cliente = clientesEmpresa[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      cliente.nombre.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    cliente.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📧 ${cliente.email}'),
                      if (cliente.telefono != null)
                        Text('📱 ${cliente.telefono}'),
                      if (cliente.direccion != null)
                        Text('📍 ${cliente.direccion}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _showEditDialog(context, ref, cliente);
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () => _deleteCliente(ref, cliente.id),
                      ),
                    ],
                  ),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref, profile?.empresaId),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, String? empresaId) {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Cliente'),
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
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
                final repository = ref.read(clienteRepositoryProvider);
                await repository.create(
                  empresaId: empresaId!,
                  nombre: nombreController.text,
                  email: emailController.text.isEmpty ? 'sin-email@example.com' : emailController.text,
                  telefono: telefonoController.text.isEmpty ? null : telefonoController.text,
                  direccion: direccionController.text.isEmpty ? null : direccionController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cliente creado exitosamente')),
                  );
                }

                ref.invalidate(clientesListProvider);
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

  void _showEditDialog(BuildContext context, WidgetRef ref, cliente) {
    final nombreController = TextEditingController(text: cliente.nombre);
    final emailController = TextEditingController(text: cliente.email ?? '');
    final telefonoController = TextEditingController(text: cliente.telefono ?? '');
    final direccionController = TextEditingController(text: cliente.direccion ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cliente'),
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
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              try {
                final repository = ref.read(clienteRepositoryProvider);
                await repository.update(
                  cliente.id,
                  {
                    'nombre': nombreController.text,
                    if (emailController.text.isNotEmpty) 'email': emailController.text,
                    if (telefonoController.text.isNotEmpty) 'telefono': telefonoController.text,
                    if (direccionController.text.isNotEmpty) 'direccion': direccionController.text,
                  },
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cliente actualizado exitosamente')),
                  );
                }

                ref.invalidate(clientesListProvider);
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

  void _deleteCliente(WidgetRef ref, String clienteId) async {
    try {
      final repository = ref.read(clienteRepositoryProvider);
      await repository.delete(clienteId);
      ref.invalidate(clientesListProvider);
    } catch (e) {
      debugPrint('Error al eliminar: $e');
    }
  }
}
