import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/core/constants/routes.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

// Importaciones de pantallas
// Auth
import 'package:marketmove_app/src/features/auth/presentation/login_page.dart';
import 'package:marketmove_app/src/features/auth/presentation/register_page.dart';

// SUPERADMIN
import 'package:marketmove_app/presentation/features/superadmin/empresas/empresas_list_page.dart';
import 'package:marketmove_app/presentation/features/superadmin/usuarios/usuarios_page.dart';

// ADMIN
import 'package:marketmove_app/presentation/features/admin/dashboard/admin_dashboard_page.dart';
import 'package:marketmove_app/presentation/features/admin/ventas/ventas_page.dart';
import 'package:marketmove_app/presentation/features/admin/gastos/gastos_page.dart';
import 'package:marketmove_app/presentation/features/admin/balance/balance_page.dart';
import 'package:marketmove_app/presentation/features/admin/productos/productos_admin_page.dart';
import 'package:marketmove_app/presentation/features/admin/clientes/clientes_admin_page.dart';
import 'package:marketmove_app/presentation/features/admin/pedidos/pedidos_admin_page.dart';

// CLIENTE
import 'package:marketmove_app/presentation/features/cliente/catalogo/catalogo_page.dart';
import 'package:marketmove_app/presentation/features/cliente/pedidos/mis_pedidos_page.dart';

// ONBOARDING
import 'package:marketmove_app/presentation/features/onboarding/welcome_page.dart';

// Placeholder para pantallas que no existen aún
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Pantalla: $title')),
    );
  }
}

/// Provider del router global
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoading = authState is AsyncLoading;
      final profile = authState.value;
      final isAuthenticated = profile != null;

      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Debug: mostrar estado actual del router
      print('🔍 ROUTER: path=${state.matchedLocation}, rol=${profile?.role.name}, empresa_id=${profile?.empresaId}');

      // Si está cargando, mantener en la ruta actual
      if (isLoading) {
        return null;
      }

      // Si no está autenticado y no está en ruta de auth, redirigir a login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Si está autenticado y está en ruta de auth, redirigir a home según rol
      if (isAuthenticated && isAuthRoute) {
        // Si no tiene empresa y NO es SUPERADMIN, redirigir a bienvenida
        if (profile.empresaId == null && profile.role.name != 'SUPERADMIN') {
          return AppRoutes.welcome;
        }
        return _getHomeRouteForRole(profile.role.name);
      }

      // Si está autenticado pero no tiene empresa (excepto SUPERADMIN), solo puede acceder a welcome
      if (isAuthenticated && profile.empresaId == null && profile.role.name != 'SUPERADMIN') {
        if (state.matchedLocation != AppRoutes.welcome && !isAuthRoute) {
          return AppRoutes.welcome;
        }
        return null; // Ya está en welcome o auth
      }

      // Validar acceso a rutas protegidas por rol
      if (isAuthenticated) {
        final currentPath = state.matchedLocation;
        // No validar rutas de auth ni welcome
        if (!isAuthRoute && currentPath != AppRoutes.welcome) {
          final hasAccess = _hasAccessToRoute(currentPath, profile.role.name);
          print('🔍 ROUTER: hasAccess=$hasAccess para path=$currentPath, rol=${profile.role.name}');
          
          if (!hasAccess) {
            // Redirigir a su home si no tiene acceso
            print('🔍 ROUTER: REDIRIGIENDO a home por falta de acceso');
            return _getHomeRouteForRole(profile.role.name);
          }
          
          // Si tiene acceso, NO redirigir (dejar que se quede donde está)
          print('🔍 ROUTER: Tiene acceso, manteniéndose en $currentPath');
        }
      }

      return null;
    },
    routes: [
      // Rutas de autenticación
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),

      // Rutas SUPERADMIN
      GoRoute(
        path: AppRoutes.superadminEmpresas,
        builder: (context, state) => const EmpresasListPage(),
      ),
      GoRoute(
        path: AppRoutes.superadminUsuarios,
        builder: (context, state) => const UsuariosPage(),
      ),

      // Rutas ADMIN
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminVentas,
        builder: (context, state) => const VentasPage(),
      ),
      GoRoute(
        path: AppRoutes.adminGastos,
        builder: (context, state) => const GastosPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBalance,
        builder: (context, state) => const BalancePage(),
      ),
      GoRoute(
        path: AppRoutes.adminProductos,
        builder: (context, state) => const ProductosAdminPage(),
      ),
      GoRoute(
        path: AppRoutes.adminClientes,
        builder: (context, state) => const ClientesAdminPage(),
      ),
      GoRoute(
        path: AppRoutes.adminPedidos,
        builder: (context, state) => const PedidosAdminPage(),
      ),

      // Rutas CLIENTE
      GoRoute(
        path: AppRoutes.clienteCatalogo,
        builder: (context, state) => const CatalogoPage(),
      ),
      GoRoute(
        path: AppRoutes.clientePedidos,
        builder: (context, state) => const MisPedidosPage(),
      ),
    ],
  );
});

/// Obtener ruta home según rol
String _getHomeRouteForRole(String role) {
  switch (role) {
    case 'SUPERADMIN':
      return AppRoutes.superadminEmpresas;
    case 'ADMIN':
      return AppRoutes.adminDashboard;
    case 'CLIENTE':
      return AppRoutes.clienteCatalogo;
    default:
      return AppRoutes.login;
  }
}

/// Validar si el usuario tiene acceso a una ruta
bool _hasAccessToRoute(String path, String role) {
  // SUPERADMIN tiene acceso a todo
  if (role == 'SUPERADMIN') {
    return true;
  }

  // ADMIN puede acceder a rutas admin
  if (role == 'ADMIN') {
    return path.startsWith('/admin');
  }

  // CLIENTE solo accede a rutas cliente
  if (role == 'CLIENTE') {
    return path.startsWith('/cliente');
  }

  return false;
}
