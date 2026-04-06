-- Función de dotación diaria por área y bloque
-- Issue: fn_dotacion_dia — pantalla diaria de dotación
--
-- Devuelve un dataset por ÁREA y BLOQUE (maniana/tarde) para la fecha dada,
-- con cobertura real vs. valores configurados en dotacion_area_bloque_config.
--
-- Incluye TODAS las áreas activas (cobertura 0 cuando no hay empleados).
-- Incluye ambos bloques siempre.
-- Respeta empleados.activo = true.
-- No tiene efectos secundarios: solo lectura/reporte.
--
-- Idempotente: CREATE OR REPLACE FUNCTION es segura de re-ejecutar.

CREATE OR REPLACE FUNCTION public.fn_dotacion_dia(p_fecha date)
RETURNS TABLE (
    fecha              date,
    dia                int,
    area_id            bigint,
    area_codigo        text,
    area_nombre        text,
    bloque             text,
    cobertura          numeric,
    min_recomendado    int,
    max_recomendado    int,
    min_intermedios    int,
    max_intermedios    int,
    faltan             numeric,
    sobran             numeric,
    empleados          jsonb
)
LANGUAGE sql
STABLE
AS $$
WITH

-- Número de día ISO (1=lunes .. 7=domingo) para la fecha pedida
dia_calc AS (
    SELECT extract(isodow from p_fecha)::int AS dia
),

-- Aportes de cada empleado activo con turno asignado en p_fecha
-- Solo se consideran empleados con asignacion_principal_area_id no nula.
aportes AS (
    SELECT
        e.id                           AS empleado_id,
        e.nombre                       AS empleado_nombre,
        e.asignacion_principal_area_id AS area_id,
        t.tipo_turno,
        eq.aporte_maniana,
        eq.aporte_tarde,
        -- Marca si ese día coincide con descanso habitual o alternativo del empleado
        (
            extract(isodow from p_fecha)::int = e.descanso_habitual_dia
            OR extract(isodow from p_fecha)::int = e.descanso_alternativo_dia
        ) AS es_descanso
    FROM public.empleados e
    JOIN public.turnos_personal t
        ON  t.empleado_id = e.id
        AND t.fecha       = p_fecha
    JOIN public.equivalencia_turno_bloque eq
        ON  eq.tipo_turno = t.tipo_turno
    WHERE e.activo                        = true
      AND e.asignacion_principal_area_id IS NOT NULL
),

-- Cobertura total por área y bloque
cobertura_area AS (
    SELECT
        area_id,
        sum(aporte_maniana) AS cobertura_maniana,
        sum(aporte_tarde)   AS cobertura_tarde
    FROM aportes
    GROUP BY area_id
),

-- Lista JSON de empleados que aportan al bloque maniana (aporte_maniana > 0)
emp_maniana AS (
    SELECT
        area_id,
        jsonb_agg(
            jsonb_build_object(
                'id',            empleado_id,
                'nombre',        empleado_nombre,
                'tipo_turno',    tipo_turno,
                'aporte_maniana', aporte_maniana,
                'aporte_tarde',   aporte_tarde,
                'es_descanso',   es_descanso
            ) ORDER BY empleado_nombre
        ) FILTER (WHERE aporte_maniana > 0) AS empleados
    FROM aportes
    GROUP BY area_id
),

-- Lista JSON de empleados que aportan al bloque tarde (aporte_tarde > 0)
emp_tarde AS (
    SELECT
        area_id,
        jsonb_agg(
            jsonb_build_object(
                'id',            empleado_id,
                'nombre',        empleado_nombre,
                'tipo_turno',    tipo_turno,
                'aporte_maniana', aporte_maniana,
                'aporte_tarde',   aporte_tarde,
                'es_descanso',   es_descanso
            ) ORDER BY empleado_nombre
        ) FILTER (WHERE aporte_tarde > 0) AS empleados
    FROM aportes
    GROUP BY area_id
),

-- Configuración de mínimos/máximos por área para el día de la semana pedido
cfg AS (
    SELECT
        area_id,
        max(CASE WHEN bloque = 'maniana' THEN min_recomendado END) AS min_maniana,
        max(CASE WHEN bloque = 'maniana' THEN max_recomendado END) AS max_maniana,
        max(CASE WHEN bloque = 'maniana' THEN min_intermedios END) AS min_int_maniana,
        max(CASE WHEN bloque = 'maniana' THEN max_intermedios END) AS max_int_maniana,
        max(CASE WHEN bloque = 'tarde'   THEN min_recomendado END) AS min_tarde,
        max(CASE WHEN bloque = 'tarde'   THEN max_recomendado END) AS max_tarde,
        max(CASE WHEN bloque = 'tarde'   THEN min_intermedios END) AS min_int_tarde,
        max(CASE WHEN bloque = 'tarde'   THEN max_intermedios END) AS max_int_tarde
    FROM public.dotacion_area_bloque_config
    WHERE dia = (SELECT dia FROM dia_calc)
    GROUP BY area_id
)

-- Proyección final: todas las áreas activas × ambos bloques
SELECT
    p_fecha                                                                     AS fecha,
    (SELECT dia FROM dia_calc)                                                  AS dia,
    ar.id                                                                       AS area_id,
    ar.codigo                                                                   AS area_codigo,
    ar.nombre                                                                   AS area_nombre,
    b.bloque,

    -- Cobertura real del bloque
    CASE b.bloque
        WHEN 'maniana' THEN coalesce(cov.cobertura_maniana, 0)
        ELSE                coalesce(cov.cobertura_tarde,   0)
    END                                                                         AS cobertura,

    -- Mínimo recomendado (0 si no hay config)
    CASE b.bloque
        WHEN 'maniana' THEN coalesce(cfg.min_maniana, 0)
        ELSE                coalesce(cfg.min_tarde,   0)
    END                                                                         AS min_recomendado,

    -- Máximo recomendado (999 si no hay config)
    CASE b.bloque
        WHEN 'maniana' THEN coalesce(cfg.max_maniana, 999)
        ELSE                coalesce(cfg.max_tarde,   999)
    END                                                                         AS max_recomendado,

    -- Mínimo de intermedios (0 si no hay config)
    CASE b.bloque
        WHEN 'maniana' THEN coalesce(cfg.min_int_maniana, 0)
        ELSE                coalesce(cfg.min_int_tarde,   0)
    END                                                                         AS min_intermedios,

    -- Máximo de intermedios (999 si no hay config)
    CASE b.bloque
        WHEN 'maniana' THEN coalesce(cfg.max_int_maniana, 999)
        ELSE                coalesce(cfg.max_int_tarde,   999)
    END                                                                         AS max_intermedios,

    -- Faltan: greatest(min - cobertura, 0)
    greatest(
        CASE b.bloque
            WHEN 'maniana' THEN coalesce(cfg.min_maniana, 0) - coalesce(cov.cobertura_maniana, 0)
            ELSE                coalesce(cfg.min_tarde,   0) - coalesce(cov.cobertura_tarde,   0)
        END,
        0
    )                                                                           AS faltan,

    -- Sobran: greatest(cobertura - max, 0)
    greatest(
        CASE b.bloque
            WHEN 'maniana' THEN coalesce(cov.cobertura_maniana, 0) - coalesce(cfg.max_maniana, 999)
            ELSE                coalesce(cov.cobertura_tarde,   0) - coalesce(cfg.max_tarde,   999)
        END,
        0
    )                                                                           AS sobran,

    -- Lista de empleados que aportan a este bloque ([] si ninguno)
    CASE b.bloque
        WHEN 'maniana' THEN coalesce(em.empleados, '[]'::jsonb)
        ELSE                coalesce(et.empleados, '[]'::jsonb)
    END                                                                         AS empleados

FROM public.areas_turnos ar
CROSS JOIN (VALUES ('maniana'::text), ('tarde'::text)) AS b(bloque)
LEFT JOIN cobertura_area cov ON cov.area_id = ar.id
LEFT JOIN cfg               ON cfg.area_id  = ar.id
LEFT JOIN emp_maniana em    ON em.area_id   = ar.id
LEFT JOIN emp_tarde   et    ON et.area_id   = ar.id

WHERE ar.activa = true
ORDER BY coalesce(ar.orden, 999), ar.codigo, b.bloque;
$$;
