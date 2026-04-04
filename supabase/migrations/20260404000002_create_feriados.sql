-- Migration: 20260404000002_create_feriados.sql
-- Purpose: Create the `feriados` table for national, provincial, commercial and
--          special holidays (1/1, 1/5, 25/12).
-- Idempotent: uses CREATE TABLE IF NOT EXISTS and CREATE INDEX IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS feriados (
  id          INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fecha       DATE NOT NULL,
  nombre      TEXT NOT NULL,
  tipo        TEXT NOT NULL,
  es_especial BOOLEAN NOT NULL DEFAULT FALSE,

  CONSTRAINT feriados_fecha_unica UNIQUE (fecha),
  CONSTRAINT feriados_tipo_valido CHECK (tipo IN ('nacional', 'provincial', 'comercio', 'especial'))
);

COMMENT ON TABLE  feriados             IS 'Catálogo de feriados nacionales, provinciales, de comercio y especiales';
COMMENT ON COLUMN feriados.fecha       IS 'Fecha del feriado';
COMMENT ON COLUMN feriados.nombre      IS 'Nombre descriptivo del feriado';
COMMENT ON COLUMN feriados.tipo        IS 'Tipo: nacional | provincial | comercio | especial';
COMMENT ON COLUMN feriados.es_especial IS 'TRUE para los 3 feriados especiales (1/1, 1/5, 25/12)';

CREATE INDEX IF NOT EXISTS idx_feriados_fecha       ON feriados (fecha);
CREATE INDEX IF NOT EXISTS idx_feriados_es_especial ON feriados (es_especial);

ALTER TABLE feriados ENABLE ROW LEVEL SECURITY;

-- Admins can do everything; authenticated users (employees) can only read
DROP POLICY IF EXISTS "admins_all_feriados"      ON feriados;
DROP POLICY IF EXISTS "empleados_leen_feriados"  ON feriados;

CREATE POLICY "admins_all_feriados"
  ON feriados
  FOR ALL
  TO authenticated
  USING     ((auth.jwt() ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "empleados_leen_feriados"
  ON feriados
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Seed the 3 special holidays (idempotent via ON CONFLICT DO NOTHING)
INSERT INTO feriados (fecha, nombre, tipo, es_especial)
VALUES
  ('2026-01-01', 'Año Nuevo',          'especial', TRUE),
  ('2026-05-01', 'Día del Trabajador', 'especial', TRUE),
  ('2026-12-25', 'Navidad',            'especial', TRUE)
ON CONFLICT (fecha) DO NOTHING;
