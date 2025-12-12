import 'package:flutter/material.dart';
import '../../../shared/services/gastos_service.dart';
import '../../../shared/services/ventas_service.dart';

class ResumenPage extends StatefulWidget {
  const ResumenPage({super.key});

  @override
  State<ResumenPage> createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {
  final _ventasService = VentasService();
  final _gastosService = GastosService();
  bool _isLoading = true;
  double _totalVentas = 0;
  double _totalGastos = 0;

  @override
  void initState() {
    super.initState();
    _loadResumen();
  }

  Future<void> _loadResumen() async {
    setState(() => _isLoading = true);
    try {
      final ventas = await _ventasService.getAll();
      final gastos = await _gastosService.getAll();
      _totalVentas = ventas.fold(0, (sum, item) => sum + item.total);
      _totalGastos = gastos.fold(0, (sum, item) => sum + item.cantidad);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando resumen: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _balance => _totalVentas - _totalGastos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen financiero')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ventas totales', style: theme.textTheme.titleLarge),
                  Text('${_totalVentas.toStringAsFixed(2)} €', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.green)),
                  const SizedBox(height: 16),
                  Text('Gastos totales', style: theme.textTheme.titleLarge),
                  Text('${_totalGastos.toStringAsFixed(2)} €', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.red)),
                  const SizedBox(height: 16),
                  const Divider(),
                  Text('Balance', style: theme.textTheme.titleLarge),
                  Text('${_balance.toStringAsFixed(2)} €', style: theme.textTheme.headlineMedium?.copyWith(color: _balance >= 0 ? Colors.green : Colors.red)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadResumen,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar datos'),
                  ),
                ],
              ),
      ),
    );
  }
}
