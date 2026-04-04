-- Migration: 20260404000003_create_turnos_personal.sql
-- Purpose: Create the main `turnos_personal` table with daily shift records per employee.
-- Idempotent: uses CREATE TABLE IF NOT EXISTS, CREATE INDEX IF NOT EXISTS,
--             CREATE OR REPLACE FUNCTION, DROP TRIGGER IF EXISTS + CREATE TRIGGER.

CREATE TABLE IF NOT EXISTS turnos_personal (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empleado_id    UUID   NOT NULL,
  fecha          DATE   NOT NULL,
  tipo_turno     TEXT   NOT NULL,
  estado         TEXT,
  compensado     BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT tp_empleado_fecha_unica  UNIQUE (empleado_id, fecha),
  CONSTRAINT tp_tipo_turno_valido     CHECK (tipo_turno IN ('manana', 'tarde', 'intermedio', 'descanso')),
  CONSTRAINT tp_estado_valido         CHECK (estado IS NULL OR estado IN ('ENF', 'CAP', 'VAC', 'X')),
  CONSTRAINT tp_estado_sin_descanso   CHECK (
    -- estados exclusivos con tipo_turno descanso (no tiene sentido ENF en descanso)
    NOT (tipo_turno = 'descanso' AND estado IS NOT NULL)
  )
);

COMMENT ON TABLE  turnos_personal              IS 'Registro diario de turnos por empleado';
COMMENT ON COLUMN turnos_personal.empleado_id  IS 'FK a la tabla empleados';
COMMENT ON COLUMN turnos_personal.fecha        IS 'Fecha del turno';
COMMENT ON COLUMN turnos_personal.tipo_turno   IS 'manana | tarde | intermedio | descanso';
COMMENT ON COLUMN turnos_personal.estado       IS 'Estado especial: ENF | CAP | VAC | X (NULL = sin novedad)';
COMMENT ON COLUMN turnos_personal.compensado   IS 'Indica si este día fue compensado por un feriado trabajado';

CREATE INDEX IF NOT EXISTS idx_tp_empleado_id ON turnos_personal (empleado_id);
CREATE INDEX IF NOT EXISTS idx_tp_fecha       ON turnos_personal (fecha);
CREATE INDEX IF NOT EXISTS idx_tp_fecha_tipo  ON turnos_personal (fecha, tipo_turno);

-- Auto-update `actualizado_en` on UPDATE
CREATE OR REPLACE FUNCTION fn_tp_set_actualizado_en()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.actualizado_en = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tp_actualizado_en ON turnos_personal;
CREATE TRIGGER trg_tp_actualizado_en
  BEFORE UPDATE ON turnos_personal
  FOR EACH ROW
  EXECUTE FUNCTION fn_tp_set_actualizado_en();

ALTER TABLE turnos_personal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admins_all_turnos_personal"  ON turnos_personal;
DROP POLICY IF EXISTS "empleados_leen_sus_turnos"   ON turnos_personal;

CREATE POLICY "admins_all_turnos_personal"
  ON turnos_personal
  FOR ALL
  TO authenticated
  USING     ((auth.jwt() ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "empleados_leen_sus_turnos"
  ON turnos_personal
  FOR SELECT
  TO authenticated
  USING (empleado_id = auth.uid());
