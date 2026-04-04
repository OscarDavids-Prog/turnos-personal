-- Migration: 20260404000006_create_especial_rotacion.sql
-- Purpose: Create the `especial_rotacion` table to track the annual rotation of
--          employees assigned to the 3 special holiday days.
-- Idempotent: uses CREATE TABLE IF NOT EXISTS, CREATE INDEX IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS especial_rotacion (
  id          INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  anio        INT  NOT NULL,
  feriado_id  INT  NOT NULL REFERENCES feriados (id) ON DELETE RESTRICT,
  empleado_id UUID NOT NULL,
  orden       INT  NOT NULL,

  CONSTRAINT er_anio_feriado_empleado_unico UNIQUE (anio, feriado_id, empleado_id),
  CONSTRAINT er_anio_valido CHECK (anio >= 2020 AND anio <= 2100),
  CONSTRAINT er_orden_positivo CHECK (orden > 0),
  CONSTRAINT er_solo_especiales CHECK (
    feriado_id IN (SELECT id FROM feriados WHERE es_especial = TRUE)
  )
);

COMMENT ON TABLE  especial_rotacion             IS 'Rotación anual del personal asignado a los 3 días especiales';
COMMENT ON COLUMN especial_rotacion.anio        IS 'Año de la rotación';
COMMENT ON COLUMN especial_rotacion.feriado_id  IS 'FK a feriados (es_especial = TRUE)';
COMMENT ON COLUMN especial_rotacion.empleado_id IS 'FK a empleados';
COMMENT ON COLUMN especial_rotacion.orden       IS 'Posición en el orden de rotación (1 = primero)';

CREATE INDEX IF NOT EXISTS idx_er_anio        ON especial_rotacion (anio);
CREATE INDEX IF NOT EXISTS idx_er_feriado_id  ON especial_rotacion (feriado_id);
CREATE INDEX IF NOT EXISTS idx_er_empleado_id ON especial_rotacion (empleado_id);

ALTER TABLE especial_rotacion ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admins_all_especial_rotacion"  ON especial_rotacion;
DROP POLICY IF EXISTS "empleados_leen_rotacion"       ON especial_rotacion;

CREATE POLICY "admins_all_especial_rotacion"
  ON especial_rotacion
  FOR ALL
  TO authenticated
  USING     ((auth.jwt() ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "empleados_leen_rotacion"
  ON especial_rotacion
  FOR SELECT
  TO authenticated
  USING (TRUE);
