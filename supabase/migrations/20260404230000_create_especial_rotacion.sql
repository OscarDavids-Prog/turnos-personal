-- Tabla para la rotación anual de feriados especiales
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.especial_rotacion (
    id BIGSERIAL PRIMARY KEY,
    empleado_id BIGINT NOT NULL REFERENCES public.empleados(id),
    feriado_id BIGINT NOT NULL REFERENCES public.feriados(id),
    anio INTEGER NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Un feriado especial solo puede asignarse una vez por año
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_especial_rotacion_feriado_anio'
    ) THEN
        CREATE UNIQUE INDEX idx_especial_rotacion_feriado_anio
        ON public.especial_rotacion (feriado_id, anio);
    END IF;
END $$;

-- Trigger para actualizar timestamp
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_especial_rotacion_actualizado_en'
    ) THEN

        CREATE OR REPLACE FUNCTION public.fn_especial_rotacion_actualizado_en()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.actualizado_en = now();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trg_especial_rotacion_actualizado_en
        BEFORE UPDATE ON public.especial_rotacion
        FOR EACH ROW EXECUTE FUNCTION public.fn_especial_rotacion_actualizado_en();
    END IF;
END $$;
