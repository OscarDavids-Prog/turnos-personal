-- Normalización de public.empleados:
--   1) Agregar columnas FK a areas_turnos (asignaciones) y dias_semana (descansos).
--   2) Agregar constraints de consistencia (sin duplicados, sin igualdad habitual/alternativo).
--   3) Eliminar columnas legacy TEXT de asignaciones y descansos.
--
-- Estrategia: add columns → (backfill si hubiera datos) → drop legacy columns.
-- Las columnas legacy actuales están todas en NULL (datos de prueba), por lo que
-- no se requiere backfill real, pero el bloque es robusto para cuando haya datos.

-- ─── 1. Agregar columnas FK (como NULL para permitir backfill antes de NOT NULL) ──

ALTER TABLE public.empleados
    ADD COLUMN IF NOT EXISTS asignacion_principal_area_id    BIGINT   NULL
        REFERENCES public.areas_turnos(id);

ALTER TABLE public.empleados
    ADD COLUMN IF NOT EXISTS asignacion_secundaria_1_area_id BIGINT   NULL
        REFERENCES public.areas_turnos(id);

ALTER TABLE public.empleados
    ADD COLUMN IF NOT EXISTS asignacion_secundaria_2_area_id BIGINT   NULL
        REFERENCES public.areas_turnos(id);

ALTER TABLE public.empleados
    ADD COLUMN IF NOT EXISTS descanso_habitual_dia           SMALLINT NULL
        REFERENCES public.dias_semana(id);

ALTER TABLE public.empleados
    ADD COLUMN IF NOT EXISTS descanso_alternativo_dia        SMALLINT NULL
        REFERENCES public.dias_semana(id);

-- ─── 2. Backfill desde TEXT legacy (solo si hay datos no nulos) ───────────────
-- Si las columnas legacy tuvieran datos, aquí se haría el mapeo.
-- Como los datos actuales son todos NULL, este bloque es un no-op seguro.

DO $$
BEGIN
    -- Backfill asignacion_principal → asignacion_principal_area_id
    IF EXISTS (
        SELECT 1 FROM public.empleados
        WHERE asignacion_principal IS NOT NULL
          AND asignacion_principal_area_id IS NULL
        LIMIT 1
    ) THEN
        UPDATE public.empleados e
        SET asignacion_principal_area_id = at.id
        FROM public.areas_turnos at
        WHERE lower(e.asignacion_principal) = at.codigo
          AND e.asignacion_principal IS NOT NULL
          AND e.asignacion_principal_area_id IS NULL;
    END IF;

    -- Backfill asignacion_secundaria_1 → asignacion_secundaria_1_area_id
    IF EXISTS (
        SELECT 1 FROM public.empleados
        WHERE asignacion_secundaria_1 IS NOT NULL
          AND asignacion_secundaria_1_area_id IS NULL
        LIMIT 1
    ) THEN
        UPDATE public.empleados e
        SET asignacion_secundaria_1_area_id = at.id
        FROM public.areas_turnos at
        WHERE lower(e.asignacion_secundaria_1) = at.codigo
          AND e.asignacion_secundaria_1 IS NOT NULL
          AND e.asignacion_secundaria_1_area_id IS NULL;
    END IF;

    -- Backfill asignacion_secundaria_2 → asignacion_secundaria_2_area_id
    IF EXISTS (
        SELECT 1 FROM public.empleados
        WHERE asignacion_secundaria_2 IS NOT NULL
          AND asignacion_secundaria_2_area_id IS NULL
        LIMIT 1
    ) THEN
        UPDATE public.empleados e
        SET asignacion_secundaria_2_area_id = at.id
        FROM public.areas_turnos at
        WHERE lower(e.asignacion_secundaria_2) = at.codigo
          AND e.asignacion_secundaria_2 IS NOT NULL
          AND e.asignacion_secundaria_2_area_id IS NULL;
    END IF;

    -- Backfill descanso_habitual (texto) → descanso_habitual_dia (1..7)
    IF EXISTS (
        SELECT 1 FROM public.empleados
        WHERE descanso_habitual IS NOT NULL
          AND descanso_habitual_dia IS NULL
        LIMIT 1
    ) THEN
        UPDATE public.empleados e
        SET descanso_habitual_dia = ds.id
        FROM public.dias_semana ds
        WHERE lower(e.descanso_habitual) = ds.nombre
          AND e.descanso_habitual IS NOT NULL
          AND e.descanso_habitual_dia IS NULL;
    END IF;

    -- Backfill descanso_alternativo (texto) → descanso_alternativo_dia (1..7)
    IF EXISTS (
        SELECT 1 FROM public.empleados
        WHERE descanso_alternativo IS NOT NULL
          AND descanso_alternativo_dia IS NULL
        LIMIT 1
    ) THEN
        UPDATE public.empleados e
        SET descanso_alternativo_dia = ds.id
        FROM public.dias_semana ds
        WHERE lower(e.descanso_alternativo) = ds.nombre
          AND e.descanso_alternativo IS NOT NULL
          AND e.descanso_alternativo_dia IS NULL;
    END IF;
END
$$;

-- ─── 3. Intentar aplicar NOT NULL en asignacion_principal_area_id ────────────
-- Solo se aplica si no quedan filas con NULL (todas migradas correctamente).
-- Si quedan NULLs (datos de prueba sin valor legacy), emite un NOTICE informativo
-- y deja la columna como nullable — la aplicación deberá forzar el valor al editar.

DO $$
DECLARE
    v_null_count integer;
BEGIN
    SELECT COUNT(*) INTO v_null_count
    FROM public.empleados
    WHERE asignacion_principal_area_id IS NULL;

    IF v_null_count = 0 THEN
        EXECUTE 'ALTER TABLE public.empleados
                 ALTER COLUMN asignacion_principal_area_id SET NOT NULL';
        RAISE NOTICE 'asignacion_principal_area_id marcada como NOT NULL.';
    ELSE
        RAISE NOTICE
            'asignacion_principal_area_id tiene % fila(s) con NULL. '
            'Columna dejada como nullable hasta que se carguen los datos reales. '
            'Ejecutar luego: ALTER TABLE public.empleados ALTER COLUMN asignacion_principal_area_id SET NOT NULL',
            v_null_count;
    END IF;
END
$$;

-- ─── 4. Agregar constraints de consistencia ───────────────────────────────────

DO $$
BEGIN
    -- secundaria_1 != principal (solo cuando secundaria_1 no es null)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_empleados_sec1_ne_principal'
          AND conrelid = 'public.empleados'::regclass
    ) THEN
        ALTER TABLE public.empleados
            ADD CONSTRAINT chk_empleados_sec1_ne_principal
            CHECK (
                asignacion_secundaria_1_area_id IS NULL
                OR asignacion_secundaria_1_area_id <> asignacion_principal_area_id
            );
    END IF;

    -- secundaria_2 != principal (solo cuando secundaria_2 no es null)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_empleados_sec2_ne_principal'
          AND conrelid = 'public.empleados'::regclass
    ) THEN
        ALTER TABLE public.empleados
            ADD CONSTRAINT chk_empleados_sec2_ne_principal
            CHECK (
                asignacion_secundaria_2_area_id IS NULL
                OR asignacion_secundaria_2_area_id <> asignacion_principal_area_id
            );
    END IF;

    -- secundaria_2 != secundaria_1 (solo cuando ambas no son null)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_empleados_sec2_ne_sec1'
          AND conrelid = 'public.empleados'::regclass
    ) THEN
        ALTER TABLE public.empleados
            ADD CONSTRAINT chk_empleados_sec2_ne_sec1
            CHECK (
                asignacion_secundaria_2_area_id IS NULL
                OR asignacion_secundaria_1_area_id IS NULL
                OR asignacion_secundaria_2_area_id <> asignacion_secundaria_1_area_id
            );
    END IF;

    -- descanso_alternativo_dia != descanso_habitual_dia (solo cuando alternativo no es null)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_empleados_descanso_alt_ne_hab'
          AND conrelid = 'public.empleados'::regclass
    ) THEN
        ALTER TABLE public.empleados
            ADD CONSTRAINT chk_empleados_descanso_alt_ne_hab
            CHECK (
                descanso_alternativo_dia IS NULL
                OR descanso_alternativo_dia <> descanso_habitual_dia
            );
    END IF;
END
$$;

-- ─── 5. Eliminar columnas TEXT legacy ────────────────────────────────────────

ALTER TABLE public.empleados
    DROP COLUMN IF EXISTS asignacion_principal;

ALTER TABLE public.empleados
    DROP COLUMN IF EXISTS asignacion_secundaria_1;

ALTER TABLE public.empleados
    DROP COLUMN IF EXISTS asignacion_secundaria_2;

ALTER TABLE public.empleados
    DROP COLUMN IF EXISTS descanso_habitual;

ALTER TABLE public.empleados
    DROP COLUMN IF EXISTS descanso_alternativo;
