import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/presentation/providers/empresa_provider.dart';
import 'package:marketmove_app/core/constants/routes.dart';

// Modelo simple para Usuario
class Usuario {
  final String id;
  final String email;
  final String nombre;
  final String role;
  final String? empresaId;

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.role,
    this.empresaId,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
      role: map['role'] ?? 'CLIENTE',
      empresaId: map['empresa_id'],
    );
  }
}

// Provider para usuarios
final usuariosProvider = FutureProvider<List<Usuario>>((ref) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .order('created_at', ascending: false);

  return (response as List).map((e) => Usuario.fromMap(e)).toList();
});

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosProvider);
    final empresasAsync = ref.watch(empresasListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.superadminEmpresas),
        ),
        title: const Text('Gestión de Usuarios'),
      ),
      body: usuariosAsync.when(
        data: (usuarios) {
          if (usuarios.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              
              Color roleColor;
              IconData roleIcon;
              switch (usuario.role) {
                case 'SUPERADMIN':
                  roleColor = Colors.purple;
                  roleIcon = Icons.admin_panel_settings;
                  break;
                case 'ADMIN':
                  roleColor = Colors.blue;
                  roleIcon = Icons.business_center;
                  break;
                default:
                  roleColor = Colors.green;
                  roleIcon = Icons.person;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor,
                        child: Icon(roleIcon, color: Colors.white),
                      ),
                      title: Text(
                        usuario.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📧 ${usuario.email}'),
                          Text('👤 Rol: ${usuario.role}'),
                          if (usuario.empresaId != null)
                            Text('🏢 Empresa asignada: ${usuario.empresaId!.substring(0, 8)}...')
                          else
                            const Text('⚠️ Sin empresa asignada', 
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                    if (usuario.empresaId == null && usuario.role != 'SUPERADMIN')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: empresasAsync.when(
                          data: (empresas) => Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _asignarEmpresa(
                                    context, 
                                    ref, 
                                    usuario, 
                                    empresas,
                                  ),
                                  icon: const Icon(Icons.business),
                                  label: const Text('Asignar Empresa'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (e, s) => Text('Error: $e'),
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
            ],
          ),
        ),
      ),
    );
  }

  void _asignarEmpresa(BuildContext context, WidgetRef ref, Usuario usuario, empresas) {
    if (empresas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay empresas disponibles. Crea una primero.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? empresaSeleccionada;
        
        return AlertDialog(
          title: Text('Asignar empresa a ${usuario.nombre}'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona una empresa:'),
                const SizedBox(height: 16),
                ...empresas.map((empresa) => RadioListTile<String>(
                  title: Text(empresa.nombre),
                  subtitle: empresa.nif.isNotEmpty ? Text('NIF: ${empresa.nif}') : null,
                  value: empresa.id,
                  groupValue: empresaSeleccionada,
                  onChanged: (value) {
                    setState(() {
                      empresaSeleccionada = value;
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: empresaSeleccionada == null ? null : () async {
                try {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({
                        'empresa_id': empresaSeleccionada,
                        'role': 'ADMIN', // Cambiar a ADMIN al asignar empresa
                      })
                      .eq('id', usuario.id);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Empresa asignada exitosamente')),
                    );
                  }

                  ref.invalidate(usuariosProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Asignar'),
            ),
          ],
        );
      },
    );
  }
}
