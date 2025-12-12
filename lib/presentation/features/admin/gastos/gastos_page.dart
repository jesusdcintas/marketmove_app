import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Modelo simple para Gasto
class Gasto {
  final String id;
  final String empresaId;
  final String concepto;
  final double monto;
  final String? categoria;
  final DateTime fecha;

  Gasto({
    required this.id,
    required this.empresaId,
    required this.concepto,
    required this.monto,
    this.categoria,
    required this.fecha,
  });

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      empresaId: map['empresa_id'],
      concepto: map['concepto'],
      monto: (map['monto'] as num).toDouble(),
      categoria: map['categoria'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}

// Provider para gastos
final gastosProvider = FutureProvider<List<Gasto>>((ref) async {
  final empresaId = ref.watch(currentEmpresaIdProvider);
  
  if (empresaId == null) return [];
  
  final response = await Supabase.instance.client
      .from('gastos')
      .select()
      .eq('empresa_id', empresaId)
      .order('fecha', ascending: false);

  return (response as List).map((e) => Gasto.fromMap(e)).toList();
});

class GastosPage extends ConsumerWidget {
  const GastosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastosAsync = ref.watch(gastosProvider);
    final profile = ref.read(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gastos'),
      ),
      body: gastosAsync.when(
        data: (gastos) {
          if (gastos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay gastos registrados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showNuevoGastoDialog(context, ref, profile?.empresaId),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Primer Gasto'),
                  ),
                ],
              ),
            );
          }

          // Calcular total de gastos
          final totalGastos = gastos.fold<double>(0, (sum, gasto) => sum + gasto.monto);

          return Column(
            children: [
              // Card resumen
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Gastos', style: TextStyle(fontSize: 14)),
                          Text(
                            '${gastos.length} gastos',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Text(
                        '€${totalGastos.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lista de gastos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: gastos.length,
                  itemBuilder: (context, index) {
                    final gasto = gastos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                        title: Text(
                          gasto.concepto,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (gasto.categoria != null)
                              Text('Categoría: ${gasto.categoria}'),
                            Text('Fecha: ${_formatDate(gasto.fecha)}'),
                          ],
                        ),
                        trailing: Text(
                          '-€${gasto.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
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
              const SizedBox(height: 8),
              Text(
                'Asegúrate de que la tabla "gastos" exista en Supabase',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNuevoGastoDialog(context, ref, profile?.empresaId),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNuevoGastoDialog(BuildContext context, WidgetRef ref, String? empresaId) {
    final conceptoController = TextEditingController();
    final montoController = TextEditingController();
    final categoriaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Gasto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Alquiler, Luz, Proveedores',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Servicios, Compras, Impuestos',
                ),
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
              if (conceptoController.text.isEmpty || montoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Concepto y monto son obligatorios')),
                );
                return;
              }

              try {
                await Supabase.instance.client.from('gastos').insert({
                  'empresa_id': empresaId,
                  'concepto': conceptoController.text,
                  'monto': double.parse(montoController.text),
                  if (categoriaController.text.isNotEmpty) 'categoria': categoriaController.text,
                  'fecha': DateTime.now().toIso8601String(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto registrado exitosamente')),
                  );
                }

                ref.invalidate(gastosProvider);
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
}
