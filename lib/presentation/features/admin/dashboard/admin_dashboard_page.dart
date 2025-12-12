import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/core/constants/routes.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';
import 'package:marketmove_app/presentation/providers/pedido_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final pedidosPendientesAsync = ref.watch(pedidosPendientesProvider);
    final authNotifier = ref.read(authProvider.notifier);
    
    // Debug: mostrar información del perfil
    print('🔍 DASHBOARD: empresa_id=${profile?.empresaId}, rol=${profile?.role.name}, empresa=${profile?.empresa?.nombre}');

    return Scaffold(
      appBar: AppBar(
        leading: profile?.isSuperAdmin == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // SUPERADMIN vuelve a su lista de empresas
                  context.go(AppRoutes.superadminEmpresas);
                },
                tooltip: 'Volver a empresas',
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            if (profile?.empresa != null)
              Text(
                profile!.empresa!.nombre,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authNotifier.signOut(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, ${profile?.nombre ?? "Admin"}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rol: ${profile?.role.name ?? ""}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Accesos rápidos
            const Text(
              'Accesos Rápidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _DashboardCard(
                  icon: Icons.point_of_sale,
                  title: 'Ventas',
                  color: Colors.green,
                  onTap: () => context.push(AppRoutes.adminVentas),
                ),
                _DashboardCard(
                  icon: Icons.money_off,
                  title: 'Gastos',
                  color: Colors.red,
                  onTap: () => context.push(AppRoutes.adminGastos),
                ),
                _DashboardCard(
                  icon: Icons.inventory,
                  title: 'Productos/Stock',
                  color: Colors.blue,
                  onTap: () => context.push(AppRoutes.adminProductos),
                ),
                _DashboardCard(
                  icon: Icons.analytics,
                  title: 'Balance',
                  color: Colors.purple,
                  onTap: () => context.push(AppRoutes.adminBalance),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pedidos pendientes
            const Text(
              'Pedidos Pendientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            pedidosPendientesAsync.when(
              data: (pedidos) {
                if (pedidos.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, size: 48, color: Colors.green[300]),
                            const SizedBox(height: 8),
                            const Text('No hay pedidos pendientes'),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pedidos.length > 5 ? 5 : pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: const Icon(Icons.pending, color: Colors.orange),
                        ),
                        title: Text('Pedido #${pedido.numeroPedido}'),
                        subtitle: Text(
                          '\$${pedido.total.toStringAsFixed(2)} - ${pedido.fechaPedido.day}/${pedido.fechaPedido.month}/${pedido.fechaPedido.year}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.go(AppRoutes.adminPedidos),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error al cargar pedidos: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
