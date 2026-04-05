-- Tabla de feriados (normales y especiales)
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.feriados (
    id BIGSERIAL PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    es_especial BOOLEAN NOT NULL DEFAULT false,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

DO $block$
BEGIN
    -- Crear función si no existe
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc
        WHERE proname = 'fn_feriados_actualizado_en'
    ) THEN
        EXECUTE $func$
        CREATE OR REPLACE FUNCTION public.fn_feriados_actualizado_en()
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
        WHERE tgname = 'trg_feriados_actualizado_en'
    ) THEN
        EXECUTE $trg$
        CREATE TRIGGER trg_feriados_actualizado_en
        BEFORE UPDATE ON public.feriados
        FOR EACH ROW
        EXECUTE FUNCTION public.fn_feriados_actualizado_en();
        $trg$;
    END IF;
END;
$block$;
