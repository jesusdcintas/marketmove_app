import 'package:flutter/material.dart';

import '../../../shared/models/producto.dart';
import '../../../shared/services/productos_service.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _service = ProductosService();
  bool _isLoading = false;
  List<Producto> _productos = [];

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await _service.getAll();
      setState(() => _productos = fetched);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando productos: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showProductoForm({Producto? producto}) async {
    final nombreController = TextEditingController(text: producto?.nombre);
    final precioController = TextEditingController(
      text: producto?.precioUnitario.toStringAsFixed(2),
    );
    final stockController = TextEditingController(text: producto?.stock.toString());

    final isEditing = producto != null;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text(isEditing ? 'Editar producto' : 'Nuevo producto'),
            content: Form(
              key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
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
                if (!formKey.currentState!.validate()) return;

                final nombre = nombreController.text.trim();
                final precio = double.tryParse(precioController.text.trim()) ?? 0;
                final stock = int.tryParse(stockController.text.trim()) ?? 0;

                try {
                  if (isEditing) {
                    await _service.update(
                      Producto(
                        id: producto.id,
                        nombre: nombre,
                        descripcion: producto.descripcion,
                        precioUnitario: precio,
                        stock: stock,
                        creado: producto.creado,
                      ),
                    );
                  } else {
                    await _service.insert(
                      Producto(
                        id: '',
                        nombre: nombre,
                        descripcion: '',
                        precioUnitario: precio,
                        stock: stock,
                      ),
                    );
                  }

                  await _loadProductos();
                  Navigator.pop(context);
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error guardando producto: $error')),
                  );
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProducto(String id) async {
    try {
      await _service.delete(id);
      await _loadProductos();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando producto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? const Center(child: Text('No hay productos registrados'))
              : ListView.builder(
                  itemCount: _productos.length,
                  itemBuilder: (context, index) {
                    final producto = _productos[index];
                    return ListTile(
                      title: Text(producto.nombre),
                      subtitle: Text('Precio: ${producto.precioUnitario.toStringAsFixed(2)} · Stock: ${producto.stock}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showProductoForm(producto: producto),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteProducto(producto.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductoForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
