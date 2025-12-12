import 'package:flutter/material.dart';

import '../../../shared/models/gasto.dart';
import '../../../shared/services/gastos_service.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final _gastosService = GastosService();
  bool _isLoading = false;
  List<Gasto> _gastos = [];
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGastos();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _loadGastos() async {
    setState(() => _isLoading = true);
    try {
      _gastos = await _gastosService.getAll();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando gastos: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGasto() async {
    final descripcion = _descripcionController.text.trim();
    final monto = double.tryParse(_montoController.text.trim()) ?? 0;

    if (descripcion.isEmpty || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descripción y monto son obligatorios.')),
      );
      return;
    }

    final gasto = Gasto(
      id: '',
      userId: '',
      descripcion: descripcion,
      cantidad: monto,
    );

    try {
      await _gastosService.insert(gasto);
      _descripcionController.clear();
      _montoController.clear();
      await _loadGastos();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando el gasto: $error')),
      );
    }
  }

  Future<void> _deleteGasto(String id) async {
    try {
      await _gastosService.delete(id);
      await _loadGastos();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando el gasto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _montoController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitGasto,
                  child: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _gastos.isEmpty
                      ? const Center(child: Text('No hay gastos registrados.'))
                      : ListView.builder(
                          itemCount: _gastos.length,
                          itemBuilder: (context, index) {
                            final gasto = _gastos[index];
                            return ListTile(
                              title: Text(gasto.descripcion),
                              subtitle: Text('Monto: ${gasto.cantidad.toStringAsFixed(2)} €'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteGasto(gasto.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
