-- Tabla para empleados con turno fijo (casos excepcionales)
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.empleado_turno_fijo (
    empleado_id BIGINT PRIMARY KEY REFERENCES public.empleados(id),
    tipo TEXT NOT NULL,         -- 'partido', 'administrativo'
    descripcion TEXT
);

-- Validación de tipos permitidos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'empleado_turno_fijo_tipo_check'
    ) THEN
        ALTER TABLE public.empleado_turno_fijo
        ADD CONSTRAINT empleado_turno_fijo_tipo_check
        CHECK (tipo IN ('partido', 'administrativo'));
    END IF;
END $$;
