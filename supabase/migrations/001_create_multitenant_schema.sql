-- =====================================================
-- MIGRACIÓN: Esquema Multi-Tenant para MarketMove CRM
-- =====================================================

-- 1. Crear tabla de empresas
CREATE TABLE IF NOT EXISTS empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  nif TEXT NOT NULL UNIQUE,
  direccion TEXT,
  telefono TEXT,
  email TEXT,
  logo_url TEXT,
  activa BOOLEAN DEFAULT true,
  plan TEXT DEFAULT 'basic',
  max_usuarios INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Crear tabla profiles para multi-tenancy
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  empresa_id UUID REFERENCES empresas(id) ON DELETE SET NULL,
  role TEXT DEFAULT 'CLIENTE' CHECK (role IN ('SUPERADMIN', 'ADMIN', 'CLIENTE')),
  nombre TEXT,
  email TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger para crear perfil automáticamente cuando se registra un usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nombre)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nombre', NEW.email)
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Si falla, registrar el error pero no bloquear el registro
    RAISE WARNING 'Error creando perfil: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Crear tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  telefono TEXT,
  direccion TEXT,
  notas TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Actualizar/crear tabla de productos para multi-tenancy
DROP TABLE IF EXISTS productos CASCADE;
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  categoria TEXT,
  imagen_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Crear tabla de pedidos
CREATE TABLE IF NOT EXISTS pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  numero_pedido TEXT NOT NULL,
  estado TEXT DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'confirmado', 'enviado', 'entregado', 'cancelado')),
  total DECIMAL(10,2) NOT NULL,
  notas TEXT,
  fecha_pedido TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fecha_entrega TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(empresa_id, numero_pedido)
);

-- 6. Crear tabla de items de pedidos
CREATE TABLE IF NOT EXISTS pedidos_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
  cantidad INTEGER NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Crear tabla de log de actividad
CREATE TABLE IF NOT EXISTS actividad_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  accion TEXT NOT NULL,
  tabla TEXT NOT NULL,
  registro_id UUID,
  detalles JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- FUNCIONES AUXILIARES PARA RLS
-- =====================================================

-- Función para obtener el rol del usuario actual
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Función para obtener la empresa del usuario actual
CREATE OR REPLACE FUNCTION get_user_empresa()
RETURNS UUID AS $$
  SELECT empresa_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Función para verificar si es superadmin
CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE((SELECT role = 'SUPERADMIN' FROM profiles WHERE id = auth.uid()), false);
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- =====================================================
-- POLÍTICAS RLS (Row Level Security)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE actividad_log ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS PARA EMPRESAS
CREATE POLICY "SUPERADMIN puede ver todas las empresas"
  ON empresas FOR SELECT
  TO authenticated
  USING (is_superadmin());

CREATE POLICY "SUPERADMIN puede crear empresas"
  ON empresas FOR INSERT
  TO authenticated
  WITH CHECK (is_superadmin());

CREATE POLICY "SUPERADMIN puede actualizar empresas"
  ON empresas FOR UPDATE
  TO authenticated
  USING (is_superadmin());

CREATE POLICY "Usuarios pueden ver su propia empresa"
  ON empresas FOR SELECT
  TO authenticated
  USING (id = get_user_empresa());

-- POLÍTICAS PARA PROFILES (sin recursión - CRITICAL: NO usar get_user_role aquí)
CREATE POLICY "Usuarios pueden ver su propio perfil"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

-- Permitir INSERT desde cualquier contexto (trigger y signup)
CREATE POLICY "Permitir inserción de perfiles"
  ON profiles FOR INSERT
  WITH CHECK (true);

-- POLÍTICAS PARA CLIENTES
CREATE POLICY "Usuarios ven clientes de su empresa"
  ON clientes FOR SELECT
  TO authenticated
  USING (empresa_id = get_user_empresa() OR is_superadmin());

CREATE POLICY "ADMIN puede crear clientes"
  ON clientes FOR INSERT
  TO authenticated
  WITH CHECK ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

CREATE POLICY "ADMIN puede actualizar clientes"
  ON clientes FOR UPDATE
  TO authenticated
  USING ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

CREATE POLICY "ADMIN puede eliminar clientes"
  ON clientes FOR DELETE
  TO authenticated
  USING ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

-- POLÍTICAS PARA PRODUCTOS
CREATE POLICY "Usuarios ven productos de su empresa"
  ON productos FOR SELECT
  TO authenticated
  USING (empresa_id = get_user_empresa() OR is_superadmin());

CREATE POLICY "ADMIN puede crear productos"
  ON productos FOR INSERT
  TO authenticated
  WITH CHECK ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

CREATE POLICY "ADMIN puede actualizar productos"
  ON productos FOR UPDATE
  TO authenticated
  USING ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

CREATE POLICY "ADMIN puede eliminar productos"
  ON productos FOR DELETE
  TO authenticated
  USING ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

-- POLÍTICAS PARA PEDIDOS
CREATE POLICY "Usuarios ven pedidos de su empresa"
  ON pedidos FOR SELECT
  TO authenticated
  USING (empresa_id = get_user_empresa() OR is_superadmin());

CREATE POLICY "ADMIN y CLIENTE pueden crear pedidos"
  ON pedidos FOR INSERT
  TO authenticated
  WITH CHECK (empresa_id = get_user_empresa() OR is_superadmin());

CREATE POLICY "ADMIN puede actualizar pedidos"
  ON pedidos FOR UPDATE
  TO authenticated
  USING ((get_user_role() IN ('ADMIN', 'SUPERADMIN')) AND (empresa_id = get_user_empresa() OR is_superadmin()));

CREATE POLICY "CLIENTE puede cancelar sus pedidos pendientes"
  ON pedidos FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid() AND estado = 'pendiente');

-- POLÍTICAS PARA ITEMS DE PEDIDOS
CREATE POLICY "Usuarios ven items de pedidos de su empresa"
  ON pedidos_items FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM pedidos 
    WHERE pedidos.id = pedidos_items.pedido_id 
    AND (pedidos.empresa_id = get_user_empresa() OR is_superadmin())
  ));

CREATE POLICY "Usuarios pueden crear items al crear pedidos"
  ON pedidos_items FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM pedidos 
    WHERE pedidos.id = pedidos_items.pedido_id 
    AND (pedidos.empresa_id = get_user_empresa() OR is_superadmin())
  ));

-- POLÍTICAS PARA LOG DE ACTIVIDAD
CREATE POLICY "SUPERADMIN puede ver todo el log"
  ON actividad_log FOR SELECT
  TO authenticated
  USING (is_superadmin());

CREATE POLICY "Usuarios ven log de su empresa"
  ON actividad_log FOR SELECT
  TO authenticated
  USING (empresa_id = get_user_empresa());

CREATE POLICY "Sistema puede insertar en log"
  ON actividad_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- =====================================================
-- TRIGGERS PARA ACTUALIZAR updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_empresas_updated_at ON empresas;
CREATE TRIGGER update_empresas_updated_at BEFORE UPDATE ON empresas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_clientes_updated_at ON clientes;
CREATE TRIGGER update_clientes_updated_at BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_productos_updated_at ON productos;
CREATE TRIGGER update_productos_updated_at BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pedidos_updated_at ON pedidos;
CREATE TRIGGER update_pedidos_updated_at BEFORE UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_profiles_empresa ON profiles(empresa_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_clientes_empresa ON clientes(empresa_id);
CREATE INDEX IF NOT EXISTS idx_productos_empresa ON productos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_productos_activo ON productos(activo);
CREATE INDEX IF NOT EXISTS idx_pedidos_empresa ON pedidos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos(estado);
CREATE INDEX IF NOT EXISTS idx_pedidos_items_pedido ON pedidos_items(pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_items_producto ON pedidos_items(producto_id);
CREATE INDEX IF NOT EXISTS idx_actividad_empresa ON actividad_log(empresa_id);

-- =====================================================
-- DATOS INICIALES (OPCIONAL)
-- =====================================================

-- Crear una empresa de prueba
INSERT INTO empresas (nombre, nif, direccion, telefono, email, activa)
VALUES ('Empresa Demo', 'B12345678', 'Calle Principal 123', '+34 600 000 000', 'demo@marketmove.com', true)
ON CONFLICT (nif) DO NOTHING;

-- Nota: Los perfiles de usuarios se crean automáticamente con triggers de auth
-- pero puedes actualizar usuarios existentes con:
-- UPDATE profiles SET empresa_id = (SELECT id FROM empresas WHERE nif = 'B12345678'), role = 'ADMIN' WHERE id = 'tu-user-id';

COMMENT ON TABLE empresas IS 'Tabla de empresas/organizaciones del sistema multi-tenant';
COMMENT ON TABLE profiles IS 'Perfiles de usuarios con rol y empresa asignada';
COMMENT ON TABLE clientes IS 'Clientes de cada empresa';
COMMENT ON TABLE productos IS 'Productos por empresa';
COMMENT ON TABLE pedidos IS 'Pedidos realizados por clientes';
COMMENT ON TABLE pedidos_items IS 'Items/líneas de cada pedido';
COMMENT ON TABLE actividad_log IS 'Registro de actividad del sistema';
