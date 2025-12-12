import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen MarketMove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Panel principal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/productos'),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Lista de productos y stock'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/ventas'),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Registrar venta'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/gastos'),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar gasto'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/resumen'),
              icon: const Icon(Icons.pie_chart_outline),
              label: const Text('Panel de balance'),
            ),
            const SizedBox(height: 12),
            const Text('Selecciona lo que quieres registrar o revisar.', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
