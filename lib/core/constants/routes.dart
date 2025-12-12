/// Rutas de navegación de la aplicación
class AppRoutes {
  // Auth
  static const login = '/login';
  static const register = '/register';
  static const welcome = '/welcome';
  
  // Superadmin
  static const superadminEmpresas = '/superadmin/empresas';
  static const superadminUsuarios = '/superadmin/usuarios';
  
  // Admin
  static const adminDashboard = '/admin/dashboard';
  static const adminVentas = '/admin/ventas';
  static const adminGastos = '/admin/gastos';
  static const adminProductos = '/admin/productos';
  static const adminBalance = '/admin/balance';
  static const adminClientes = '/admin/clientes';
  static const adminPedidos = '/admin/pedidos';
  
  // Cliente
  static const clienteCatalogo = '/cliente/catalogo';
  static const clientePedidos = '/cliente/pedidos';
  static const clienteCarrito = '/cliente/carrito';
}
