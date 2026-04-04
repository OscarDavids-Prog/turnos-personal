-- Migration: 20260404000005_create_feriado_especial_trabajado.sql
-- Purpose: Create the `feriado_especial_trabajado` table to record work done on
--          the 3 special holidays (1/1, 1/5, 25/12). These are paid separately.
-- Idempotent: uses CREATE TABLE IF NOT EXISTS, CREATE INDEX IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS feriado_especial_trabajado (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empleado_id UUID   NOT NULL,
  feriado_id  INT    NOT NULL REFERENCES feriados (id) ON DELETE RESTRICT,
  tipo_turno  TEXT   NOT NULL,
  creado_en   TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fet_empleado_feriado_unico UNIQUE (empleado_id, feriado_id),
  CONSTRAINT fet_tipo_turno_valido      CHECK  (tipo_turno IN ('manana', 'tarde', 'intermedio')),
  CONSTRAINT fet_solo_especiales CHECK (
    -- Only special holidays are registered here
    feriado_id IN (SELECT id FROM feriados WHERE es_especial = TRUE)
  )
);

COMMENT ON TABLE  feriado_especial_trabajado             IS 'Feriados especiales (1/1, 1/5, 25/12) trabajados – pago aparte';
COMMENT ON COLUMN feriado_especial_trabajado.empleado_id IS 'FK a empleados';
COMMENT ON COLUMN feriado_especial_trabajado.feriado_id  IS 'FK a feriados (es_especial = TRUE)';
COMMENT ON COLUMN feriado_especial_trabajado.tipo_turno  IS 'Turno único del día especial: manana | tarde | intermedio';

CREATE INDEX IF NOT EXISTS idx_fet_empleado_id ON feriado_especial_trabajado (empleado_id);
CREATE INDEX IF NOT EXISTS idx_fet_feriado_id  ON feriado_especial_trabajado (feriado_id);

ALTER TABLE feriado_especial_trabajado ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admins_all_feriado_especial_trabajado"      ON feriado_especial_trabajado;
DROP POLICY IF EXISTS "empleados_leen_sus_feriados_especiales"     ON feriado_especial_trabajado;

CREATE POLICY "admins_all_feriado_especial_trabajado"
  ON feriado_especial_trabajado
  FOR ALL
  TO authenticated
  USING     ((auth.jwt() ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "empleados_leen_sus_feriados_especiales"
  ON feriado_especial_trabajado
  FOR SELECT
  TO authenticated
  USING (empleado_id = auth.uid());
