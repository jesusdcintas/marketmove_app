-- =====================================================
-- AGREGAR TABLA DE GASTOS
-- =====================================================

CREATE TABLE IF NOT EXISTS gastos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  concepto TEXT NOT NULL,
  monto DECIMAL(10, 2) NOT NULL CHECK (monto > 0),
  categoria TEXT,
  fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_gastos_empresa ON gastos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_gastos_fecha ON gastos(fecha DESC);

-- RLS (Row Level Security) deshabilitado para consistencia
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;

-- Política simple: usuarios autenticados tienen acceso total
CREATE POLICY "gastos_select_authenticated"
  ON gastos FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "gastos_insert_authenticated"
  ON gastos FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "gastos_update_authenticated"
  ON gastos FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "gastos_delete_authenticated"
  ON gastos FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_gastos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gastos_updated_at
  BEFORE UPDATE ON gastos
  FOR EACH ROW
  EXECUTE FUNCTION update_gastos_updated_at();

-- Permisos
GRANT ALL ON gastos TO authenticated;
GRANT ALL ON gastos TO anon;
