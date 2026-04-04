-- Extensión de la tabla empleados con atributos estables
-- Idempotente: solo agrega columnas si no existen

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS fecha_nacimiento date;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS direccion text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS fecha_ingreso date;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS categoria text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS asignacion_principal text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS asignacion_secundaria_1 text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS asignacion_secundaria_2 text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS descanso_habitual text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS descanso_alternativo text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS cbu text;

ALTER TABLE public.empleados
  ADD COLUMN IF NOT EXISTS cvu text;
