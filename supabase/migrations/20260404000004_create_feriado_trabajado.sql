-- Migration: 20260404000004_create_feriado_trabajado.sql
-- Purpose: Create the `feriado_trabajado` table to record regular (non-special)
--          holidays worked by an employee, with their compensation modality.
-- Idempotent: uses CREATE TABLE IF NOT EXISTS, CREATE INDEX IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS feriado_trabajado (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empleado_id UUID   NOT NULL,
  feriado_id  INT    NOT NULL REFERENCES feriados (id) ON DELETE RESTRICT,
  modalidad   TEXT   NOT NULL,
  creado_en   TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT ft_empleado_feriado_unico UNIQUE (empleado_id, feriado_id),
  CONSTRAINT ft_modalidad_valida       CHECK  (modalidad IN ('compensado', 'cobrado')),
  CONSTRAINT ft_no_especial CHECK (
    -- Only non-special holidays are registered here
    feriado_id IN (SELECT id FROM feriados WHERE es_especial = FALSE)
  )
);

COMMENT ON TABLE  feriado_trabajado             IS 'Feriados normales (no especiales) trabajados por cada empleado';
COMMENT ON COLUMN feriado_trabajado.empleado_id IS 'FK a empleados';
COMMENT ON COLUMN feriado_trabajado.feriado_id  IS 'FK a feriados (es_especial = FALSE)';
COMMENT ON COLUMN feriado_trabajado.modalidad   IS 'compensado = día libre posterior | cobrado = pago extra';

CREATE INDEX IF NOT EXISTS idx_ft_empleado_id ON feriado_trabajado (empleado_id);
CREATE INDEX IF NOT EXISTS idx_ft_feriado_id  ON feriado_trabajado (feriado_id);

ALTER TABLE feriado_trabajado ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admins_all_feriado_trabajado"              ON feriado_trabajado;
DROP POLICY IF EXISTS "empleados_leen_sus_feriados_trabajados"    ON feriado_trabajado;

CREATE POLICY "admins_all_feriado_trabajado"
  ON feriado_trabajado
  FOR ALL
  TO authenticated
  USING     ((auth.jwt() ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "empleados_leen_sus_feriados_trabajados"
  ON feriado_trabajado
  FOR SELECT
  TO authenticated
  USING (empleado_id = auth.uid());
