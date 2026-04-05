-- Tabla principal de turnos asignados al personal
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.turnos_personal (
    id BIGSERIAL PRIMARY KEY,
    empleado_id BIGINT NOT NULL REFERENCES public.empleados(id),
    fecha DATE NOT NULL,
    tipo_turno TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'normal',
    observacion TEXT,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT turnos_tipo_check CHECK (
        tipo_turno IN ('maniana', 'tarde', 'mixto', 'partido', 'libre', 'no_asignado')
    ),

    CONSTRAINT turnos_estado_check CHECK (
        estado IN ('normal', 'enfermo', 'capacitacion', 'vacaciones', 'falta', 'franco', 'compensado')
    )
);

-- Evitar duplicados por empleado + fecha
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_turnos_personal_unique'
    ) THEN
        CREATE UNIQUE INDEX idx_turnos_personal_unique
        ON public.turnos_personal (empleado_id, fecha);
    END IF;
END $$;

-- Índice para consultas por fecha
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_turnos_personal_fecha'
    ) THEN
        CREATE INDEX idx_turnos_personal_fecha
        ON public.turnos_personal (fecha);
    END IF;
END $$;

DO $block$
BEGIN
    -- Crear función si no existe
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'fn_turnos_personal_actualizado_en'
    ) THEN
        EXECUTE $func$
        CREATE OR REPLACE FUNCTION public.fn_turnos_personal_actualizado_en()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.actualizado_en = now();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        $func$;
    END IF;

    -- Crear trigger si no existe
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_turnos_personal_actualizado_en'
    ) THEN
        EXECUTE $trg$
        CREATE TRIGGER trg_turnos_personal_actualizado_en
        BEFORE UPDATE ON public.turnos_personal
        FOR EACH ROW
        EXECUTE FUNCTION public.fn_turnos_personal_actualizado_en();
        $trg$;
    END IF;
END;
$block$;
