import 'package:flutter/material.dart';

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
            onPressed: () {
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
            const Text('Bienvenido al panel principal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/productos'),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Gestionar productos'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/ventas'),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Registrar ventas'),
            ),
            const SizedBox(height: 12),
            const Text('Selecciona una sección para abrir su panel correspondiente.', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
