/// Roles disponibles en el sistema CRM multi-tenant
enum UserRole {
  /// Super administrador del sistema - acceso total
  SUPERADMIN,
  
  /// Administrador de una empresa específica
  ADMIN,
  
  /// Cliente de una empresa - acceso limitado a catálogo y pedidos
  CLIENTE;

  /// Verifica si el rol tiene permisos de administración
  bool get isAdmin => this == SUPERADMIN || this == ADMIN;
  
  /// Verifica si es super administrador
  bool get isSuperAdmin => this == SUPERADMIN;
  
  /// Verifica si es cliente
  bool get isCliente => this == CLIENTE;
}
