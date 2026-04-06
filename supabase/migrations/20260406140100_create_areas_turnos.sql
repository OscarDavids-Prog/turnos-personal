-- Catálogo de áreas operativas del negocio
-- Idempotente: crea tabla y seed solo si no existen

CREATE TABLE IF NOT EXISTS public.areas_turnos (
    id     BIGSERIAL PRIMARY KEY,
    codigo TEXT    NOT NULL UNIQUE,
    nombre TEXT    NOT NULL UNIQUE,
    activa BOOLEAN NOT NULL DEFAULT true,
    orden  INT     NULL
);

-- Seed: insertar solo filas faltantes (por codigo)
INSERT INTO public.areas_turnos (codigo, nombre, orden)
VALUES
    ('lavadero',      'Lavadero',      1),
    ('plancha',       'Plancha',       2),
    ('pr_persona',    'PR Persona',    3),
    ('pr_delantales', 'PR Delantales', 4),
    ('toallas',       'Toallas',       5),
    ('desmanche',     'Desmanche',     6),
    ('reparto',       'Reparto',       7),
    ('mostrador',     'Mostrador',     8),
    ('mantenimiento', 'Mantenimiento', 9)
ON CONFLICT (codigo) DO NOTHING;
