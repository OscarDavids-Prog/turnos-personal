-- Tabla para disponibilidad variable por día del empleado
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.empleado_disponibilidad (
    id BIGSERIAL PRIMARY KEY,
    empleado_id BIGINT NOT NULL REFERENCES public.empleados(id),
    dia_semana TEXT NOT NULL,
    turno TEXT NOT NULL,
    observacion TEXT,
    CONSTRAINT disponibilidad_turno_check CHECK (
        turno IN ('maniana', 'tarde', 'mixto', 'no_disponible')
    )
);

-- Evitar duplicados por empleado + día
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE indexname = 'idx_empleado_disponibilidad_unique'
    ) THEN
        CREATE UNIQUE INDEX idx_empleado_disponibilidad_unique
        ON public.empleado_disponibilidad (empleado_id, dia_semana);
    END IF;
END $$;
