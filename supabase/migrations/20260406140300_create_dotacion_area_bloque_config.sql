-- Matriz de dotación mínima/máxima por área, día y bloque
-- Idempotente: crea tabla solo si no existe

CREATE TABLE IF NOT EXISTS public.dotacion_area_bloque_config (
    id              BIGSERIAL    PRIMARY KEY,
    area_id         BIGINT       NOT NULL REFERENCES public.areas_turnos(id),
    dia             SMALLINT     NOT NULL REFERENCES public.dias_semana(id),
    bloque          TEXT         NOT NULL,
    min_recomendado INT          NOT NULL DEFAULT 0,
    max_recomendado INT          NOT NULL DEFAULT 999,
    min_intermedios INT          NOT NULL DEFAULT 0,
    max_intermedios INT          NOT NULL DEFAULT 999,

    CONSTRAINT dotacion_bloque_check CHECK (bloque IN ('maniana', 'tarde')),
    CONSTRAINT dotacion_min_lte_max  CHECK (min_recomendado <= max_recomendado),
    CONSTRAINT dotacion_min_int_lte_max_int CHECK (min_intermedios <= max_intermedios),
    CONSTRAINT dotacion_area_dia_bloque_uq UNIQUE (area_id, dia, bloque)
);

-- Índice de soporte para consultas por área
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_dotacion_area_bloque_config_area_id'
    ) THEN
        CREATE INDEX idx_dotacion_area_bloque_config_area_id
        ON public.dotacion_area_bloque_config (area_id);
    END IF;
END $$;
