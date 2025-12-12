import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/core/constants/routes.dart';
import 'package:marketmove_app/data/models/crm_models.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';
import 'package:marketmove_app/presentation/providers/pedido_provider.dart';

/// Provider para pedidos del cliente actual
final misPedidosProvider = FutureProvider<List<Pedido>>((ref) async {
  final repository = ref.watch(pedidoRepositoryProvider);
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  // En un escenario real, filtrarías por el cliente asociado al userId
  return repository.getAll(empresaId: empresaId);
});

class MisPedidosPage extends ConsumerWidget {
  const MisPedidosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(misPedidosProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.clienteCatalogo),
        ),
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authNotifier.signOut(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: pedidosAsync.when(
        data: (pedidos) {
          if (pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes pedidos',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.clienteCatalogo),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Ver catálogo'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getEstadoColor(pedido.estado),
                    child: Icon(_getEstadoIcon(pedido.estado), color: Colors.white),
                  ),
                  title: Text(
                    'Pedido #${pedido.numeroPedido}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.estado.displayName,
                        style: TextStyle(
                          color: _getEstadoColor(pedido.estado),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${pedido.fechaPedido.day}/${pedido.fechaPedido.month}/${pedido.fechaPedido.year}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '\$${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  children: [
                    const Divider(),
                    if (pedido.notas != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pedido.notas!)),
                          ],
                        ),
                      ),
                    if (pedido.fechaEntrega != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Entrega: ${pedido.fechaEntrega!.day}/${pedido.fechaEntrega!.month}/${pedido.fechaEntrega!.year}',
                            ),
                          ],
                        ),
                      ),
                    if (pedido.estado == EstadoPedido.pendiente)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelarPedido(context, ref, pedido.id),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar Pedido'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
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
              Text('Error al cargar pedidos: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(misPedidosProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.clienteCatalogo),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Nuevo Pedido'),
      ),
    );
  }

  Color _getEstadoColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return Colors.orange;
      case EstadoPedido.confirmado:
        return Colors.blue;
      case EstadoPedido.enviado:
        return Colors.purple;
      case EstadoPedido.entregado:
        return Colors.green;
      case EstadoPedido.cancelado:
        return Colors.red;
    }
  }

  IconData _getEstadoIcon(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return Icons.pending;
      case EstadoPedido.confirmado:
        return Icons.check_circle;
      case EstadoPedido.enviado:
        return Icons.local_shipping;
      case EstadoPedido.entregado:
        return Icons.done_all;
      case EstadoPedido.cancelado:
        return Icons.cancel;
    }
  }

  void _cancelarPedido(BuildContext context, WidgetRef ref, String pedidoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Estás seguro de que deseas cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(pedidoRepositoryProvider);
                await repository.cancelar(pedidoId);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pedido cancelado')),
                  );
                }
                
                ref.invalidate(misPedidosProvider);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}
