-- Tabla para registrar feriados normales trabajados
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.feriado_trabajado (
    id BIGSERIAL PRIMARY KEY,
    empleado_id BIGINT NOT NULL REFERENCES public.empleados(id),
    feriado_id BIGINT NOT NULL REFERENCES public.feriados(id),
    fecha_trabajada DATE NOT NULL,
    modo TEXT NOT NULL, -- 'compensado' o 'cobrado'
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT feriado_trabajado_modo_check CHECK (
        modo IN ('compensado', 'cobrado')
    )
);

-- Evitar duplicados por empleado + feriado
-- Tabla para registrar feriados normales trabajados
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.feriado_trabajado (
    id BIGSERIAL PRIMARY KEY,
    empleado_id BIGINT NOT NULL REFERENCES public.empleados(id),
    feriado_id BIGINT NOT NULL REFERENCES public.feriados(id),
    fecha_trabajada DATE NOT NULL,
    modo TEXT NOT NULL, -- 'compensado' o 'cobrado'
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT feriado_trabajado_modo_check CHECK (
        modo IN ('compensado', 'cobrado')
    )
);

-- Evitar duplicados por empleado + feriado
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE indexname = 'idx_feriado_trabajado_unique'
    ) THEN
        CREATE UNIQUE INDEX idx_feriado_trabajado_unique
        ON public.feriado_trabajado (empleado_id, feriado_id);
    END IF;
END $$;

-- Trigger para actualizar timestamp
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_feriado_trabajado_actualizado_en'
    ) THEN

        CREATE OR REPLACE FUNCTION public.fn_feriado_trabajado_actualizado_en()
        RETURNS TRIGGER
        AS $func$
        BEGIN
            NEW.actualizado_en = now();
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql;

        CREATE TRIGGER trg_feriado_trabajado_actualizado_en
        BEFORE UPDATE ON public.feriado_trabajado
        FOR EACH ROW
        EXECUTE FUNCTION public.fn_feriado_trabajado_actualizado_en();
    END IF;
END $$;
