-- Tabla para registrar feriados especiales trabajados
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.feriado_especial_trabajado (
    id BIGSERIAL PRIMARY KEY,
    empleado_id BIGINT NOT NULL REFERENCES public.empleados(id),
    feriado_id BIGINT NOT NULL REFERENCES public.feriados(id),
    fecha_trabajada DATE NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Evitar duplicados por empleado + feriado especial
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_feriado_especial_trabajado_unique'
    ) THEN
        CREATE UNIQUE INDEX idx_feriado_especial_trabajado_unique
        ON public.feriado_especial_trabajado (empleado_id, feriado_id);
    END IF;
END $$;

-- Trigger para actualizar timestamp
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_feriado_especial_trabajado_actualizado_en'
    ) THEN

        CREATE OR REPLACE FUNCTION public.fn_feriado_especial_trabajado_actualizado_en()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.actualizado_en = now();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trg_feriado_especial_trabajado_actualizado_en
        BEFORE UPDATE ON public.feriado_especial_trabajado
        FOR EACH ROW EXECUTE FUNCTION public.fn_feriado_especial_trabajado_actualizado_en();
    END IF;
END $$;
