import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/presentation/providers/pedido_provider.dart';
import 'package:marketmove_app/presentation/features/admin/gastos/gastos_page.dart';
import 'package:marketmove_app/data/models/crm_models.dart';

class BalancePage extends ConsumerWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(pedidosListProvider);
    final gastosAsync = ref.watch(gastosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Balance Financiero'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen de ganancias
            pedidosAsync.when(
              data: (pedidos) {
                final ventas = pedidos.where((p) => p.estado == EstadoPedido.entregado).toList();
                final totalVentas = ventas.fold<double>(0, (sum, v) => sum + v.total);

                return Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.green, size: 32),
                            const SizedBox(width: 12),
                            const Text(
                              'Ganancias Totales',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '€${totalVentas.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${ventas.length} ventas completadas',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, s) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error al cargar ventas: $e'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Resumen de gastos
            gastosAsync.when(
              data: (gastos) {
                final totalGastos = gastos.fold<double>(0, (sum, g) => sum + g.monto);

                return Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, color: Colors.red, size: 32),
                            const SizedBox(width: 12),
                            const Text(
                              'Gastos Totales',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '€${totalGastos.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '${gastos.length} gastos registrados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, s) => Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text('No hay datos de gastos'),
                      const SizedBox(height: 4),
                      Text(
                        'Crea la tabla "gastos" en Supabase',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Balance neto
            pedidosAsync.when(
              data: (pedidos) {
                return gastosAsync.when(
                  data: (gastos) {
                    final ventas = pedidos.where((p) => p.estado == EstadoPedido.entregado).toList();
                    final totalVentas = ventas.fold<double>(0, (sum, v) => sum + v.total);
                    final totalGastos = gastos.fold<double>(0, (sum, g) => sum + g.monto);
                    final balance = totalVentas - totalGastos;
                    final isPositive = balance >= 0;

                    return Card(
                      color: isPositive ? Colors.blue[50] : Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPositive ? Icons.trending_up : Icons.trending_down,
                                  color: isPositive ? Colors.blue : Colors.orange,
                                  size: 36,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Balance Neto',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${isPositive ? "+" : ""}€${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.blue : Colors.orange,
                              ),
                            ),
                            Text(
                              isPositive ? 'Ganancia' : 'Pérdida',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, s) => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No se puede calcular balance sin datos de gastos'),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, s) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Información adicional
            const Text(
              'Detalles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Fórmula de cálculo:', 'Ventas - Gastos'),
                    const Divider(),
                    _buildInfoRow('Solo ventas entregadas:', 'Se cuentan como ganancias'),
                    const Divider(),
                    _buildInfoRow('Actualización:', 'Tiempo real'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
