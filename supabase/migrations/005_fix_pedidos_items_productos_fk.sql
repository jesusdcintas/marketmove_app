-- =====================================================
-- FIX: Agregar foreign key entre pedidos_items y productos
-- =====================================================

-- Primero, verificar si la columna existe
DO $$ 
BEGIN
    -- Si no existe la columna producto_id, crearla
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'pedidos_items' 
        AND column_name = 'producto_id'
    ) THEN
        ALTER TABLE pedidos_items 
        ADD COLUMN producto_id UUID;
    END IF;
END $$;

-- Ahora agregar la foreign key si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'pedidos_items_producto_id_fkey'
        AND table_name = 'pedidos_items'
    ) THEN
        ALTER TABLE pedidos_items
        ADD CONSTRAINT pedidos_items_producto_id_fkey
        FOREIGN KEY (producto_id) 
        REFERENCES productos(id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- Verificar la estructura
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'pedidos_items'
ORDER BY ordinal_position;
