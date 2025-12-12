import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/presentation/providers/pedido_provider.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';
import 'package:marketmove_app/data/models/crm_models.dart';

class PedidosAdminPage extends ConsumerWidget {
  const PedidosAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(pedidosListProvider);
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gestión de Pedidos'),
      ),
      body: pedidosAsync.when(
        data: (pedidos) {
          // Filtrar por empresa del ADMIN
          final pedidosEmpresa = profile?.empresaId != null
              ? pedidos.where((p) => p.empresaId == profile!.empresaId).toList()
              : pedidos;

          if (pedidosEmpresa.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay pedidos registrados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidosEmpresa.length,
            itemBuilder: (context, index) {
              final pedido = pedidosEmpresa[index];
              
              Color statusColor;
              IconData statusIcon;
              switch (pedido.estado) {
                case EstadoPedido.pendiente:
                  statusColor = Colors.orange;
                  statusIcon = Icons.pending;
                  break;
                case EstadoPedido.confirmado:
                  statusColor = Colors.blue;
                  statusIcon = Icons.check_circle_outline;
                  break;
                case EstadoPedido.enviado:
                  statusColor = Colors.purple;
                  statusIcon = Icons.local_shipping;
                  break;
                case EstadoPedido.entregado:
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case EstadoPedido.cancelado:
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(statusIcon, color: Colors.white),
                  ),
                  title: Text(
                    'Pedido #${pedido.numeroPedido}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente ID: ${pedido.clienteId.substring(0, 8)}'),
                      Text('Total: €${pedido.total.toStringAsFixed(2)}'),
                      Text('Estado: ${pedido.estado.displayName}'),
                      Text('Fecha: ${_formatDate(pedido.createdAt)}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      if (pedido.estado == EstadoPedido.pendiente)
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.check_circle_outline),
                            title: Text('Confirmar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _updateEstado(ref, pedido.id, EstadoPedido.confirmado),
                        ),
                      if (pedido.estado == EstadoPedido.confirmado)
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.local_shipping),
                            title: Text('Marcar como enviado'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _updateEstado(ref, pedido.id, EstadoPedido.enviado),
                        ),
                      if (pedido.estado == EstadoPedido.enviado)
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.check_circle),
                            title: Text('Marcar como entregado'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _updateEstado(ref, pedido.id, EstadoPedido.entregado),
                        ),
                      if (pedido.estado != EstadoPedido.cancelado && pedido.estado != EstadoPedido.entregado)
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.cancel, color: Colors.red),
                            title: Text('Cancelar pedido'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _updateEstado(ref, pedido.id, EstadoPedido.cancelado),
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateEstado(WidgetRef ref, String pedidoId, EstadoPedido nuevoEstado) async {
    try {
      final repository = ref.read(pedidoRepositoryProvider);
      await repository.updateEstado(pedidoId, nuevoEstado);
      ref.invalidate(pedidosListProvider);
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
    }
  }
}
