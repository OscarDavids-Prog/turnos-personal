-- Migration: 20260404000001_add_columns_empleados.sql
-- Purpose: Extend the existing `empleados` table with new columns required by
--          the turnos-personal module. Does NOT modify existing columns or constraints.
-- Idempotent: uses ADD COLUMN IF NOT EXISTS throughout.

ALTER TABLE empleados
  ADD COLUMN IF NOT EXISTS fecha_nacimiento      DATE,
  ADD COLUMN IF NOT EXISTS direccion             TEXT,
  ADD COLUMN IF NOT EXISTS fecha_ingreso         DATE,
  ADD COLUMN IF NOT EXISTS categoria             TEXT,
  ADD COLUMN IF NOT EXISTS asignacion_principal  TEXT,
  ADD COLUMN IF NOT EXISTS asignacion_secundaria_1 TEXT,
  ADD COLUMN IF NOT EXISTS asignacion_secundaria_2 TEXT,
  ADD COLUMN IF NOT EXISTS descanso_habitual     TEXT,
  ADD COLUMN IF NOT EXISTS descanso_alternativo  TEXT;

COMMENT ON COLUMN empleados.fecha_nacimiento       IS 'Fecha de nacimiento del empleado';
COMMENT ON COLUMN empleados.direccion              IS 'Dirección postal del empleado';
COMMENT ON COLUMN empleados.fecha_ingreso          IS 'Fecha de ingreso a Lavasol';
COMMENT ON COLUMN empleados.categoria             IS 'Categoría laboral del empleado';
COMMENT ON COLUMN empleados.asignacion_principal   IS 'Sección principal asignada (Lavadero, Plancha, Prensa, Secado, Reparto)';
COMMENT ON COLUMN empleados.asignacion_secundaria_1 IS 'Primera asignación secundaria opcional';
COMMENT ON COLUMN empleados.asignacion_secundaria_2 IS 'Segunda asignación secundaria opcional';
COMMENT ON COLUMN empleados.descanso_habitual      IS 'Día de descanso habitual (ej: domingo)';
COMMENT ON COLUMN empleados.descanso_alternativo   IS 'Día de descanso alternativo opcional';
