import 'package:flutter/material.dart';

import '../../../shared/models/producto.dart';
import '../../../shared/models/venta.dart';
import '../../../shared/services/productos_service.dart';
import '../../../shared/services/ventas_service.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final _ventasService = VentasService();
  final _productosService = ProductosService();
  final _cantidadController = TextEditingController(text: '1');
  bool _isLoading = false;
  List<Venta> _ventas = [];
  List<Producto> _productos = [];
  Producto? _selectedProducto;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productosService.getAll();
      final ventas = await _ventasService.getAll();
      setState(() {
        _productos = productos;
        _ventas = ventas;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _calculatedTotal {
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;
    return (_selectedProducto?.precio ?? 0) * cantidad;
  }

  Future<void> _showNuevaVentaForm() async {
    _selectedProducto ??= _productos.isNotEmpty ? _productos.first : null;
    _cantidadController.text = '1';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar venta'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              void notify() => setDialogState(() {});

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Producto>(
                    value: _selectedProducto,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: _productos
                        .map((producto) => DropdownMenuItem(
                              value: producto,
                              child: Text(producto.nombre),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedProducto = value;
                      });
                    },
                  ),
                  TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => notify(),
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ${_calculatedTotal.toStringAsFixed(2)} €'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedProducto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecciona un producto primero.')),
                  );
                  return;
                }

                final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;
                if (cantidad <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa una cantidad válida.')),
                  );
                  return;
                }

                final venta = Venta(
                  id: '',
                  userId: '',
                  productoId: _selectedProducto!.id,
                  unidades: cantidad,
                  total: _calculatedTotal,
                );

                try {
                  await _ventasService.insert(venta);
                  await _loadData();
                  Navigator.pop(context);
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error registrando venta: $error')),
                  );
                }
              },
              child: const Text('Guardar venta'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVenta(String id) async {
    try {
      await _ventasService.delete(id);
      await _loadData();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando venta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ventas.isEmpty
              ? const Center(child: Text('Todavía no hay ventas registradas.'))
              : ListView.builder(
                  itemCount: _ventas.length,
                  itemBuilder: (context, index) {
                    final venta = _ventas[index];
                    final producto = _productos.firstWhere(
                      (item) => item.id == venta.productoId,
                      orElse: () => Producto(
                        id: venta.productoId,
                        userId: '',
                        nombre: 'Producto desconocido',
                        precio: 0,
                        stock: 0,
                      ),
                    );

                    return ListTile(
                      title: Text(producto.nombre),
                      subtitle: Text('Cantidad: ${venta.unidades} · Total: ${venta.total.toStringAsFixed(2)} €'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever),
                        onPressed: () => _deleteVenta(venta.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNuevaVentaForm,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
