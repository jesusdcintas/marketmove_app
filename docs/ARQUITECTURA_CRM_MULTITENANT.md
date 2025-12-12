# Arquitectura CRM Multi-Tenant Flutter + Supabase
## Diseño por: Arquitecto Senior Flutter + Supabase

---

## 1. MODELO DE BASE DE DATOS

### Tabla: profiles
Control de usuarios y roles con aislamiento por empresa.

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('SUPERADMIN', 'ADMIN', 'CLIENTE')),
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  telefono TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints de seguridad
  CONSTRAINT superadmin_no_empresa CHECK (
    (role = 'SUPERADMIN' AND empresa_id IS NULL) OR
    (role != 'SUPERADMIN' AND empresa_id IS NOT NULL)
  )
);

CREATE INDEX idx_profiles_empresa ON profiles(empresa_id);
CREATE INDEX idx_profiles_role ON profiles(role);
```

### Tabla: empresas
Entidades principales del multi-tenant.

```sql
CREATE TABLE empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  nif TEXT UNIQUE NOT NULL,
  direccion TEXT,
  telefono TEXT,
  email TEXT,
  logo_url TEXT,
  activa BOOLEAN DEFAULT true,
  plan TEXT DEFAULT 'basic' CHECK (plan IN ('basic', 'premium', 'enterprise')),
  max_usuarios INT DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_empresas_activa ON empresas(activa);
```

### Tabla: productos
Productos específicos de cada empresa.

```sql
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  categoria TEXT,
  imagen_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_productos_empresa ON productos(empresa_id);
CREATE INDEX idx_productos_activo ON productos(activo);
```

### Tabla: clientes
Clientes específicos de cada empresa (además de los usuarios CLIENTE).

```sql
CREATE TABLE clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  telefono TEXT,
  direccion TEXT,
  notas TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(empresa_id, email)
);

CREATE INDEX idx_clientes_empresa ON clientes(empresa_id);
CREATE INDEX idx_clientes_user ON clientes(user_id);
```

### Tabla: pedidos
Pedidos realizados por clientes a empresas.

```sql
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  numero_pedido TEXT GENERATED ALWAYS AS (LPAD(id::text, 10, '0')) STORED,
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (
    estado IN ('pendiente', 'confirmado', 'enviado', 'entregado', 'cancelado')
  ),
  total DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  notas TEXT,
  fecha_pedido TIMESTAMPTZ DEFAULT NOW(),
  fecha_entrega TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pedidos_empresa ON pedidos(empresa_id);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
```

### Tabla: pedidos_items
Líneas de pedido (productos en cada pedido).

```sql
CREATE TABLE pedidos_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
  subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pedidos_items_pedido ON pedidos_items(pedido_id);
CREATE INDEX idx_pedidos_items_producto ON pedidos_items(producto_id);
```

### Tabla: actividad_log (opcional pero recomendado)
Auditoría de acciones críticas.

```sql
CREATE TABLE actividad_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  empresa_id UUID REFERENCES empresas(id) ON DELETE SET NULL,
  accion TEXT NOT NULL,
  tabla TEXT NOT NULL,
  registro_id UUID,
  detalles JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_actividad_log_user ON actividad_log(user_id);
CREATE INDEX idx_actividad_log_empresa ON actividad_log(empresa_id);
CREATE INDEX idx_actividad_log_created ON actividad_log(created_at DESC);
```

---

## 2. POLÍTICAS RLS (Row Level Security)

### IMPORTANTE: Habilitar RLS en todas las tablas
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE actividad_log ENABLE ROW LEVEL SECURITY;
```

### Helper function: get_user_role
```sql
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_empresa()
RETURNS UUID AS $$
  SELECT empresa_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'SUPERADMIN'
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;
```

### Policies para PROFILES

```sql
-- SUPERADMIN: todo
CREATE POLICY "SUPERADMIN puede ver todos los profiles"
ON profiles FOR SELECT
TO authenticated
USING (is_superadmin());

CREATE POLICY "SUPERADMIN puede insertar profiles"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (is_superadmin());

CREATE POLICY "SUPERADMIN puede actualizar profiles"
ON profiles FOR UPDATE
TO authenticated
USING (is_superadmin());

CREATE POLICY "SUPERADMIN puede eliminar profiles"
ON profiles FOR DELETE
TO authenticated
USING (is_superadmin());

-- ADMIN: solo su empresa
CREATE POLICY "ADMIN puede ver profiles de su empresa"
ON profiles FOR SELECT
TO authenticated
USING (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
);

CREATE POLICY "ADMIN puede insertar profiles en su empresa"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa() AND
  role = 'CLIENTE'
);

CREATE POLICY "ADMIN puede actualizar profiles de su empresa"
ON profiles FOR UPDATE
TO authenticated
USING (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa() AND
  id != auth.uid()
);

-- CLIENTE: solo su propio perfil
CREATE POLICY "CLIENTE puede ver su propio perfil"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "CLIENTE puede actualizar su propio perfil"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (
  id = auth.uid() AND 
  role = 'CLIENTE' AND
  empresa_id = get_user_empresa()
);
```

### Policies para EMPRESAS

```sql
-- SUPERADMIN: todo
CREATE POLICY "SUPERADMIN gestiona empresas"
ON empresas FOR ALL
TO authenticated
USING (is_superadmin())
WITH CHECK (is_superadmin());

-- ADMIN: solo su empresa (lectura)
CREATE POLICY "ADMIN puede ver su empresa"
ON empresas FOR SELECT
TO authenticated
USING (
  (get_user_role() = 'ADMIN' AND id = get_user_empresa()) OR
  (get_user_role() = 'CLIENTE' AND id = get_user_empresa())
);

-- ADMIN puede actualizar datos de su empresa
CREATE POLICY "ADMIN puede actualizar su empresa"
ON empresas FOR UPDATE
TO authenticated
USING (get_user_role() = 'ADMIN' AND id = get_user_empresa())
WITH CHECK (get_user_role() = 'ADMIN' AND id = get_user_empresa());
```

### Policies para PRODUCTOS

```sql
-- SUPERADMIN: todo
CREATE POLICY "SUPERADMIN gestiona productos"
ON productos FOR ALL
TO authenticated
USING (is_superadmin())
WITH CHECK (is_superadmin());

-- ADMIN: solo su empresa
CREATE POLICY "ADMIN gestiona productos de su empresa"
ON productos FOR ALL
TO authenticated
USING (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
)
WITH CHECK (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
);

-- CLIENTE: solo lectura de productos activos de su empresa
CREATE POLICY "CLIENTE ve productos activos de su empresa"
ON productos FOR SELECT
TO authenticated
USING (
  get_user_role() = 'CLIENTE' AND 
  empresa_id = get_user_empresa() AND
  activo = true
);
```

### Policies para CLIENTES

```sql
-- SUPERADMIN: todo
CREATE POLICY "SUPERADMIN gestiona clientes"
ON clientes FOR ALL
TO authenticated
USING (is_superadmin())
WITH CHECK (is_superadmin());

-- ADMIN: solo su empresa
CREATE POLICY "ADMIN gestiona clientes de su empresa"
ON clientes FOR ALL
TO authenticated
USING (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
)
WITH CHECK (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
);

-- CLIENTE: solo su propio registro
CREATE POLICY "CLIENTE ve su propio registro"
ON clientes FOR SELECT
TO authenticated
USING (
  get_user_role() = 'CLIENTE' AND 
  user_id = auth.uid()
);
```

### Policies para PEDIDOS

```sql
-- SUPERADMIN: todo
CREATE POLICY "SUPERADMIN gestiona pedidos"
ON pedidos FOR ALL
TO authenticated
USING (is_superadmin())
WITH CHECK (is_superadmin());

-- ADMIN: solo su empresa
CREATE POLICY "ADMIN gestiona pedidos de su empresa"
ON pedidos FOR ALL
TO authenticated
USING (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
)
WITH CHECK (
  get_user_role() = 'ADMIN' AND 
  empresa_id = get_user_empresa()
);

-- CLIENTE: solo sus pedidos
CREATE POLICY "CLIENTE gestiona sus pedidos"
ON pedidos FOR ALL
TO authenticated
USING (
  get_user_role() = 'CLIENTE' AND 
  user_id = auth.uid() AND
  empresa_id = get_user_empresa()
)
WITH CHECK (
  get_user_role() = 'CLIENTE' AND 
  user_id = auth.uid() AND
  empresa_id = get_user_empresa()
);
```

### Policies para PEDIDOS_ITEMS

```sql
-- SUPERADMIN: todo
CREATE POLICY "SUPERADMIN gestiona items"
ON pedidos_items FOR ALL
TO authenticated
USING (is_superadmin())
WITH CHECK (is_superadmin());

-- ADMIN y CLIENTE: via JOIN con pedidos
CREATE POLICY "Usuarios gestionan items de sus pedidos"
ON pedidos_items FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM pedidos 
    WHERE pedidos.id = pedidos_items.pedido_id
    AND (
      (get_user_role() = 'ADMIN' AND pedidos.empresa_id = get_user_empresa()) OR
      (get_user_role() = 'CLIENTE' AND pedidos.user_id = auth.uid())
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM pedidos 
    WHERE pedidos.id = pedidos_items.pedido_id
    AND (
      (get_user_role() = 'ADMIN' AND pedidos.empresa_id = get_user_empresa()) OR
      (get_user_role() = 'CLIENTE' AND pedidos.user_id = auth.uid())
    )
  )
);
```

---

## 3. TRIGGERS Y FUNCIONES AUXILIARES

### Auto-crear perfil al registrarse
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role, nombre)
  VALUES (
    NEW.id,
    NEW.email,
    'CLIENTE',
    COALESCE(NEW.raw_user_meta_data->>'nombre', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Actualizar updated_at automáticamente
```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER empresas_updated_at BEFORE UPDATE ON empresas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER productos_updated_at BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER clientes_updated_at BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER pedidos_updated_at BEFORE UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Recalcular total del pedido
```sql
CREATE OR REPLACE FUNCTION recalcular_total_pedido()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE pedidos
  SET total = (
    SELECT COALESCE(SUM(subtotal), 0)
    FROM pedidos_items
    WHERE pedido_id = COALESCE(NEW.pedido_id, OLD.pedido_id)
  )
  WHERE id = COALESCE(NEW.pedido_id, OLD.pedido_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER recalcular_total_insert
  AFTER INSERT ON pedidos_items
  FOR EACH ROW EXECUTE FUNCTION recalcular_total_pedido();

CREATE TRIGGER recalcular_total_update
  AFTER UPDATE ON pedidos_items
  FOR EACH ROW EXECUTE FUNCTION recalcular_total_pedido();

CREATE TRIGGER recalcular_total_delete
  AFTER DELETE ON pedidos_items
  FOR EACH ROW EXECUTE FUNCTION recalcular_total_pedido();
```

---

## 4. FLUJO DE AUTENTICACIÓN Y AUTORIZACIÓN

### 4.1 Registro de nuevos usuarios

**SUPERADMIN crea ADMIN de empresa:**
1. SUPERADMIN crea empresa nueva
2. SUPERADMIN registra usuario con role='ADMIN' y empresa_id asignado
3. Se envía email de bienvenida al ADMIN
4. ADMIN completa su perfil

**ADMIN crea CLIENTE:**
1. ADMIN registra usuario con role='CLIENTE' y empresa_id=su_empresa
2. Se crea registro en tabla `clientes` vinculado al user_id
3. CLIENTE recibe credenciales

### 4.2 Login y verificación de permisos

```dart
// Después del login
final user = supabase.auth.currentUser;
final profile = await supabase
  .from('profiles')
  .select('*, empresas(*)')
  .eq('id', user!.id)
  .single();

// Guardar en state global
AppState.currentProfile = Profile.fromMap(profile);
AppState.currentRole = profile['role'];
AppState.currentEmpresa = profile['empresas'];
```

### 4.3 Guards de navegación

```dart
bool canAccessRoute(String route, String userRole) {
  final routePermissions = {
    '/superadmin/empresas': ['SUPERADMIN'],
    '/admin/dashboard': ['SUPERADMIN', 'ADMIN'],
    '/admin/productos': ['SUPERADMIN', 'ADMIN'],
    '/admin/clientes': ['SUPERADMIN', 'ADMIN'],
    '/admin/pedidos': ['SUPERADMIN', 'ADMIN'],
    '/cliente/productos': ['SUPERADMIN', 'ADMIN', 'CLIENTE'],
    '/cliente/pedidos': ['SUPERADMIN', 'ADMIN', 'CLIENTE'],
  };
  
  return routePermissions[route]?.contains(userRole) ?? false;
}
```

---

## 5. ESTRUCTURA DE CARPETAS FLUTTER

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   └── supabase_config.dart
│   ├── constants/
│   │   ├── roles.dart
│   │   └── routes.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
│
├── data/
│   ├── models/
│   │   ├── profile.dart
│   │   ├── empresa.dart
│   │   ├── producto.dart
│   │   ├── cliente.dart
│   │   ├── pedido.dart
│   │   └── pedido_item.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── empresa_repository.dart
│   │   ├── producto_repository.dart
│   │   ├── cliente_repository.dart
│   │   └── pedido_repository.dart
│   └── services/
│       └── supabase_service.dart
│
├── domain/
│   ├── entities/
│   │   └── user_session.dart
│   └── use_cases/
│       ├── create_pedido_use_case.dart
│       └── manage_empresa_use_case.dart
│
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── empresa_provider.dart
│   │   ├── producto_provider.dart
│   │   └── pedido_provider.dart
│   │
│   ├── guards/
│   │   └── role_guard.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── role_restricted_widget.dart
│   │   │   ├── empresa_selector.dart
│   │   │   └── loading_overlay.dart
│   │   └── layouts/
│   │       ├── admin_layout.dart
│   │       └── cliente_layout.dart
│   │
│   └── features/
│       ├── auth/
│       │   ├── login_page.dart
│       │   ├── register_page.dart
│       │   └── widgets/
│       │
│       ├── superadmin/
│       │   ├── empresas/
│       │   │   ├── empresas_list_page.dart
│       │   │   ├── empresa_form_page.dart
│       │   │   └── widgets/
│       │   └── usuarios/
│       │       ├── usuarios_list_page.dart
│       │       └── usuario_form_page.dart
│       │
│       ├── admin/
│       │   ├── dashboard/
│       │   │   └── dashboard_page.dart
│       │   ├── productos/
│       │   │   ├── productos_list_page.dart
│       │   │   ├── producto_form_page.dart
│       │   │   └── widgets/
│       │   ├── clientes/
│       │   │   ├── clientes_list_page.dart
│       │   │   └── cliente_form_page.dart
│       │   └── pedidos/
│       │       ├── pedidos_list_page.dart
│       │       ├── pedido_detail_page.dart
│       │       └── widgets/
│       │
│       └── cliente/
│           ├── catalogo/
│           │   ├── productos_page.dart
│           │   └── producto_detail_page.dart
│           ├── carrito/
│           │   └── carrito_page.dart
│           └── mis_pedidos/
│               ├── pedidos_page.dart
│               └── pedido_detail_page.dart
│
└── routes/
    └── app_router.dart
```

---

## 6. EJEMPLOS DE CÓDIGO

### 6.1 Modelo Profile

```dart
class Profile {
  final String id;
  final String email;
  final UserRole role;
  final String? empresaId;
  final String nombre;
  final String? telefono;
  final bool activo;
  final Empresa? empresa;

  const Profile({
    required this.id,
    required this.email,
    required this.role,
    this.empresaId,
    required this.nombre,
    this.telefono,
    required this.activo,
    this.empresa,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      email: map['email'],
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      empresaId: map['empresa_id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      activo: map['activo'] ?? true,
      empresa: map['empresas'] != null ? Empresa.fromMap(map['empresas']) : null,
    );
  }

  bool get isSuperAdmin => role == UserRole.SUPERADMIN;
  bool get isAdmin => role == UserRole.ADMIN;
  bool get isCliente => role == UserRole.CLIENTE;
}

enum UserRole {
  SUPERADMIN,
  ADMIN,
  CLIENTE,
}
```

### 6.2 AuthProvider (con Riverpod)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<Profile?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<Profile?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _init() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _loadProfile(user.id);
    } else {
      state = const AsyncValue.data(null);
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _loadProfile(user.id);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, empresas(*)')
          .eq('id', userId)
          .single();

      state = AsyncValue.data(Profile.fromMap(response));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // _loadProfile se llama automáticamente vía listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Profile? get currentProfile => state.value;
  UserRole? get currentRole => state.value?.role;
  String? get currentEmpresaId => state.value?.empresaId;
}
```

### 6.3 RoleGuard

```dart
class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    required this.allowedRoles,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authProvider);

        return authState.when(
          data: (profile) {
            if (profile == null) {
              return fallback ?? const Center(child: Text('No autenticado'));
            }
            
            if (allowedRoles.contains(profile.role)) {
              return child;
            }
            
            return fallback ?? const Center(child: Text('Acceso denegado'));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        );
      },
    );
  }
}

// Uso:
RoleGuard(
  allowedRoles: [UserRole.ADMIN, UserRole.SUPERADMIN],
  child: AdminDashboard(),
  fallback: UnauthorizedPage(),
)
```

### 6.4 ProductoRepository (multi-tenant seguro)

```dart
class ProductoRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Producto>> getAll() async {
    // RLS automáticamente filtra por empresa
    final response = await _supabase
        .from('productos')
        .select()
        .order('nombre');

    return (response as List)
        .map((item) => Producto.fromMap(item))
        .toList();
  }

  Future<void> insert(Producto producto, String empresaId) async {
    final payload = producto.toMap();
    payload['empresa_id'] = empresaId;
    payload.remove('id');

    await _supabase.from('productos').insert(payload);
  }

  Future<void> update(Producto producto) async {
    await _supabase
        .from('productos')
        .update(producto.toMap())
        .eq('id', producto.id);
    // RLS verifica que sea de la empresa correcta
  }

  Future<void> delete(String id) async {
    await _supabase.from('productos').delete().eq('id', id);
  }
}
```

### 6.5 App Router con guards

```dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final profile = ref.read(authProvider).value;
    
    if (profile == null && !state.matchedLocation.startsWith('/login')) {
      return '/login';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    
    // SUPERADMIN routes
    GoRoute(
      path: '/superadmin',
      redirect: _superAdminGuard,
      routes: [
        GoRoute(
          path: 'empresas',
          builder: (context, state) => const EmpresasListPage(),
        ),
        GoRoute(
          path: 'usuarios',
          builder: (context, state) => const UsuariosListPage(),
        ),
      ],
    ),
    
    // ADMIN routes
    GoRoute(
      path: '/admin',
      redirect: _adminGuard,
      routes: [
        GoRoute(
          path: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: 'productos',
          builder: (context, state) => const ProductosListPage(),
        ),
        GoRoute(
          path: 'pedidos',
          builder: (context, state) => const PedidosListPage(),
        ),
      ],
    ),
    
    // CLIENTE routes
    GoRoute(
      path: '/cliente',
      redirect: _clienteGuard,
      routes: [
        GoRoute(
          path: 'catalogo',
          builder: (context, state) => const ProductosPage(),
        ),
        GoRoute(
          path: 'pedidos',
          builder: (context, state) => const MisPedidosPage(),
        ),
      ],
    ),
  ],
);

String? _superAdminGuard(BuildContext context, GoRouterState state) {
  final profile = ref.read(authProvider).value;
  if (profile?.role != UserRole.SUPERADMIN) {
    return '/login';
  }
  return null;
}

String? _adminGuard(BuildContext context, GoRouterState state) {
  final profile = ref.read(authProvider).value;
  if (profile?.role != UserRole.ADMIN && profile?.role != UserRole.SUPERADMIN) {
    return '/login';
  }
  return null;
}

String? _clienteGuard(BuildContext context, GoRouterState state) {
  final profile = ref.read(authProvider).value;
  if (profile == null) {
    return '/login';
  }
  return null;
}
```

---

## 7. BUENAS PRÁCTICAS DE SEGURIDAD

### 7.1 Nunca confíes solo en el cliente
- Siempre valida en RLS policies
- No almacenes lógica de negocio crítica solo en Flutter
- Usa funciones de Postgres para validaciones complejas

### 7.2 Principio de mínimo privilegio
- Cada rol solo accede a lo estrictamente necesario
- CLIENTE nunca ve datos de otras empresas
- ADMIN nunca accede a funciones de SUPERADMIN

### 7.3 Auditoría
- Registra acciones críticas en `actividad_log`
- Monitorea cambios en empresas y usuarios
- Implementa soft-delete donde sea crítico

### 7.4 Validación de empresa_id
- Siempre verifica `empresa_id` en inserts
- Usa constraints de base de datos
- No permitas cambios de `empresa_id` en updates

### 7.5 Gestión de sesiones
- Refresca el perfil después de cambios de rol
- Invalida sesiones al desactivar usuarios
- Implementa timeout de sesión

### 7.6 Testing de RLS
```sql
-- Test como ADMIN
SET request.jwt.claim.sub = 'admin-user-id';
SELECT * FROM productos; -- Solo debe ver su empresa

-- Test como CLIENTE
SET request.jwt.claim.sub = 'cliente-user-id';
SELECT * FROM productos WHERE activo = false; -- No debe ver nada
```

---

## 8. MIGRACIÓN DESDE TU PROYECTO ACTUAL

### Paso 1: Crear tablas nuevas
Ejecuta el SQL del modelo de datos en Supabase SQL Editor.

### Paso 2: Migrar tabla `profiles`
```sql
-- Agregar columnas nuevas
ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'CLIENTE';
ALTER TABLE profiles ADD COLUMN empresa_id UUID REFERENCES empresas(id);

-- Marcar tu usuario como SUPERADMIN
UPDATE profiles SET role = 'SUPERADMIN', empresa_id = NULL
WHERE id = 'tu-user-id';
```

### Paso 3: Migrar datos existentes
```sql
-- Crear empresa de prueba
INSERT INTO empresas (nombre, nif, email)
VALUES ('Mi Empresa', '12345678A', 'admin@miempresa.com')
RETURNING id;

-- Asignar usuarios existentes a esa empresa
UPDATE profiles SET empresa_id = 'empresa-id-recien-creado'
WHERE role != 'SUPERADMIN';
```

### Paso 4: Aplicar RLS
Ejecuta todas las policies definidas arriba.

### Paso 5: Actualizar código Flutter
- Instalar `flutter_riverpod` o tu state manager preferido
- Implementar `AuthProvider` y cargar perfil completo
- Refactorizar rutas con guards
- Actualizar servicios para respetar multi-tenancy

---

## RESUMEN DE ARQUITECTURA

**Seguridad**: 
- RLS en todas las tablas
- Validación doble (cliente + servidor)
- Aislamiento total por empresa_id

**Escalabilidad**:
- Cada empresa es independiente
- Fácil agregar nuevos roles
- Indices optimizados por empresa

**Mantenibilidad**:
- Estructura clara de carpetas
- Separación de responsabilidades
- Código reutilizable (guards, widgets)

**Flexibilidad**:
- SUPERADMIN puede hacer override
- ADMIN gestiona su empresa
- CLIENTE solo consume

Este diseño te permite crecer de 1 a 1000 empresas sin cambios estructurales.
