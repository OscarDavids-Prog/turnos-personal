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

-- Trigger para actualizar timestamp
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_feriados_actualizado_en'
    ) THEN

        CREATE OR REPLACE FUNCTION public.fn_feriados_actualizado_en()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.actualizado_en = now();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trg_feriados_actualizado_en
        BEFORE UPDATE ON public.feriados
        FOR EACH ROW EXECUTE FUNCTION public.fn_feriados_actualizado_en();
    END IF;
END $$;

-- Seed inicial de feriados especiales (idempotente)
INSERT INTO public.feriados (fecha, descripcion, es_especial)
VALUES 
    ('2026-01-01', 'Año Nuevo', true),
    ('2026-05-01', 'Día del Trabajador', true),
    ('2026-12-25', 'Navidad', true)
ON CONFLICT (fecha) DO NOTHING;
