import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/presentation/providers/pedido_provider.dart';
import 'package:marketmove_app/presentation/providers/producto_provider.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';
import 'package:marketmove_app/data/models/crm_models.dart';

class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});

  @override
  ConsumerState<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends ConsumerState<VentasPage> {
  @override
  Widget build(BuildContext context) {
    final pedidosAsync = ref.watch(pedidosListProvider);
    final profile = ref.read(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ventas'),
      ),
      body: pedidosAsync.when(
        data: (pedidos) {
          // Filtrar solo pedidos de esta empresa que estén entregados (ventas completadas)
          final ventas = profile?.empresaId != null
              ? pedidos.where((p) => 
                  p.empresaId == profile!.empresaId && 
                  p.estado == EstadoPedido.entregado
                ).toList()
              : [];

          if (ventas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ventas registradas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showNuevaVentaDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Primera Venta'),
                  ),
                ],
              ),
            );
          }

          // Calcular total de ventas
          final totalVentas = ventas.fold<double>(0, (sum, venta) => sum + venta.total);

          return Column(
            children: [
              // Card resumen
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Ventas', style: TextStyle(fontSize: 14)),
                          Text(
                            '${ventas.length} ventas',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Text(
                        '€${totalVentas.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lista de ventas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ventas.length,
                  itemBuilder: (context, index) {
                    final venta = ventas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          'Venta #${venta.numeroPedido}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cliente: ${venta.clienteId.substring(0, 8)}'),
                            Text('Fecha: ${_formatDate(venta.fechaPedido)}'),
                          ],
                        ),
                        trailing: Text(
                          '€${venta.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
        onPressed: () => _showNuevaVentaDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNuevaVentaDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(currentProfileProvider);
    
    // Estado local del diálogo
    final Map<String, int> productosSeleccionados = {};

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, child) {
          final productosAsync = dialogRef.watch(productosListProvider);
          
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Nueva Venta'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: productosAsync.when(
                    data: (productos) {
                      final productosEmpresa = productos
                          .where((p) => p.empresaId == profile?.empresaId && p.activo)
                          .toList();
                      
                      if (productosEmpresa.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay productos disponibles. Crea productos primero.'),
                        );
                      }
                      
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selecciona productos y cantidades:', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...productosEmpresa.map((producto) {
                              final cantidadSeleccionada = productosSeleccionados[producto.id] ?? 0;
                              final isSeleccionado = cantidadSeleccionada > 0;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: isSeleccionado,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                if (value == true) {
                                                  productosSeleccionados[producto.id] = 1;
                                                } else {
                                                  productosSeleccionados.remove(producto.id);
                                                }
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(producto.nombre, 
                                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text('€${producto.precio.toStringAsFixed(2)} - Stock: ${producto.stock}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isSeleccionado)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline),
                                              onPressed: cantidadSeleccionada > 1 ? () {
                                                setDialogState(() {
                                                  productosSeleccionados[producto.id] = cantidadSeleccionada - 1;
                                                });
                                              } : null,
                                            ),
                                            Text('Cantidad: $cantidadSeleccionada',
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline),
                                              onPressed: cantidadSeleccionada < producto.stock ? () {
                                                setDialogState(() {
                                                  productosSeleccionados[producto.id] = cantidadSeleccionada + 1;
                                                });
                                              } : null,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (productosSeleccionados.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Total: €${_calcularTotal(productos, productosSeleccionados).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, s) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error al cargar productos: $e'),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: productosSeleccionados.isEmpty ? null : () async {
                      try {
                        // Mostrar loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator()),
                        );
                        
                        await _crearVenta(ref, productosSeleccionados);
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Cerrar loading
                          Navigator.pop(context); // Cerrar diálogo
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Venta registrada correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Cerrar loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Registrar Venta'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _calcularTotal(List<ProductoMultiTenant> productos, Map<String, int> seleccionados) {
    double total = 0;
    for (var entry in seleccionados.entries) {
      final producto = productos.firstWhere((p) => p.id == entry.key);
      total += producto.precio * entry.value;
    }
    return total;
  }

  Future<void> _crearVenta(WidgetRef ref, Map<String, int> productosSeleccionados) async {
    try {
      final profile = ref.read(currentProfileProvider);
      if (profile?.empresaId == null) return;

      final productos = await ref.read(productosListProvider.future);
      final pedidoRepo = ref.read(pedidoRepositoryProvider);

      // Preparar items para el pedido
      final items = productosSeleccionados.entries.map((entry) {
        final producto = productos.firstWhere((p) => p.id == entry.key);
        return {
          'producto_id': producto.id,
          'cantidad': entry.value,
          'precio_unitario': producto.precio,
        };
      }).toList();

      // Crear cliente genérico "Venta Directa" si no existe
      final clienteResponse = await Supabase.instance.client
          .from('clientes')
          .select()
          .eq('empresa_id', profile!.empresaId!)
          .eq('nombre', 'Venta Directa')
          .maybeSingle();

      String clienteId;
      if (clienteResponse == null) {
        // Crear cliente genérico
        final nuevoCliente = await Supabase.instance.client
            .from('clientes')
            .insert({
              'empresa_id': profile.empresaId,
              'nombre': 'Venta Directa',
              'email': 'venta.directa@sistema.local',
            })
            .select()
            .single();
        clienteId = nuevoCliente['id'];
      } else {
        clienteId = clienteResponse['id'];
      }

      // Crear pedido como entregado (venta completada)
      await pedidoRepo.create(
        empresaId: profile.empresaId!,
        clienteId: clienteId,
        items: items,
      );

      // Marcar el pedido como entregado inmediatamente
      final pedidosActualizados = await Supabase.instance.client
          .from('pedidos')
          .select()
          .eq('empresa_id', profile.empresaId!)
          .eq('cliente_id', clienteId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      await Supabase.instance.client
          .from('pedidos')
          .update({'estado': EstadoPedido.entregado.name})
          .eq('id', pedidosActualizados['id']);

      ref.invalidate(pedidosListProvider);
    } catch (e) {
      print('Error al crear venta: $e');
      rethrow;
    }
  }
}
