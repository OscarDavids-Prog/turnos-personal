-- Catálogo de días de la semana (1=lunes .. 7=domingo)
-- Idempotente: crea tabla y seed solo si no existen

CREATE TABLE IF NOT EXISTS public.dias_semana (
    id   SMALLINT PRIMARY KEY,
    nombre TEXT    NOT NULL UNIQUE,
    CONSTRAINT dias_semana_id_check CHECK (id BETWEEN 1 AND 7)
);

-- Seed: insertar solo filas faltantes
INSERT INTO public.dias_semana (id, nombre)
VALUES
    (1, 'lunes'),
    (2, 'martes'),
    (3, 'miercoles'),
    (4, 'jueves'),
    (5, 'viernes'),
    (6, 'sabado'),
    (7, 'domingo')
ON CONFLICT (id) DO NOTHING;
