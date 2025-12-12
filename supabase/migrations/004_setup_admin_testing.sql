-- =====================================================
-- SCRIPT PARA PROBAR FUNCIONALIDADES DE ADMIN
-- =====================================================

-- 1. Crear una empresa de prueba si no existe
INSERT INTO empresas (nombre, nif, direccion, telefono, activa)
VALUES 
  ('Empresa Demo', '12345678A', 'Calle Principal 123', '600123456', true)
ON CONFLICT DO NOTHING;

-- 2. Obtener el ID de la empresa creada y asignar al usuario ADMIN
DO $$
DECLARE
  empresa_demo_id UUID;
  usuario_email TEXT := 'jdcintas.admin@example.com';
BEGIN
  -- Obtener ID de la empresa
  SELECT id INTO empresa_demo_id 
  FROM empresas 
  WHERE nombre = 'Empresa Demo' 
  LIMIT 1;

  -- Asignar la empresa al usuario y hacerlo ADMIN
  UPDATE profiles 
  SET 
    empresa_id = empresa_demo_id,
    role = 'ADMIN'
  WHERE email = usuario_email;

  RAISE NOTICE 'Usuario % actualizado a ADMIN con empresa asignada', usuario_email;
END $$;

-- 3. Verificar el cambio
SELECT 
  p.email,
  p.nombre,
  p.role,
  e.nombre as empresa
FROM profiles p
LEFT JOIN empresas e ON p.empresa_id = e.id
WHERE p.email = 'jdcintas.admin@example.com';

-- =====================================================
-- ALTERNATIVA: Crear productos de prueba
-- =====================================================

-- Insertar productos de prueba para la empresa
INSERT INTO productos (empresa_id, nombre, categoria, precio, stock, activo)
SELECT 
  e.id,
  producto.nombre,
  producto.categoria,
  producto.precio,
  producto.stock,
  true
FROM empresas e,
  (VALUES 
    ('Laptop HP', 'Electrónica', 799.99, 10),
    ('Mouse Logitech', 'Accesorios', 25.50, 50),
    ('Teclado Mecánico', 'Accesorios', 89.99, 30),
    ('Monitor 24"', 'Electrónica', 199.99, 15)
  ) AS producto(nombre, categoria, precio, stock)
WHERE e.nombre = 'Empresa Demo'
ON CONFLICT DO NOTHING;

-- =====================================================
-- NOTA: Después de ejecutar esto, cierra sesión y 
-- vuelve a iniciar sesión en la app
-- =====================================================
