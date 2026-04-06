-- Función parametrizada de grilla semanal de turnos
-- Etapa 3 — Issue #20: https://github.com/OscarDavids-Prog/turnos-personal/issues/20
--
-- NORMALIZACIÓN DE dia_semana
-- La tabla public.empleado_disponibilidad almacena dia_semana como TEXT.
-- Criterio adoptado: valores en español, minúsculas, sin tilde en 'miercoles'/'sabado'
-- para evitar dependencia del locale.  Mapa ISODOW → nombre:
--   1 → 'lunes' | 2 → 'martes' | 3 → 'miercoles' | 4 → 'jueves'
--   5 → 'viernes' | 6 → 'sabado' | 7 → 'domingo'
-- ISODOW es independiente del locale de la BD (a diferencia de to_char(...,'TMDay')).
-- Los datos de empleado_disponibilidad deben seguir este mismo criterio al insertarse.
--
-- Idempotente: CREATE OR REPLACE FUNCTION es segura de re-ejecutar.

CREATE OR REPLACE FUNCTION public.fn_turnos_semana(
    p_desde date,
    p_hasta date
)
RETURNS TABLE (
    -- Empleado
    empleado_id                         bigint,
    empleado_nombre                     text,
    empleado_activo                     boolean,
    modalidad                           text,
    tipo_relacion                       text,
    asignacion_principal                text,
    asignacion_secundaria_1             text,
    asignacion_secundaria_2             text,
    descanso_habitual                   text,
    descanso_alternativo                text,
    -- Calendario
    fecha                               date,
    dow                                 int,
    dia_semana                          text,
    -- Turno (nullable cuando no hay registro en turnos_personal)
    turno_id                            bigint,
    tipo_turno                          text,
    estado                              text,
    observacion                         text,
    turno_realizado                     boolean,
    horas_normales                      integer,
    -- Disponibilidad / turno fijo
    disponibilidad_turno                text,
    turno_fijo_tipo                     text,
    -- Feriados
    es_feriado                          boolean,
    es_especial                         boolean,
    feriado_id                          bigint,
    feriado_descripcion                 text,
    feriado_especial_asignado           boolean,
    -- Validaciones operativas
    persona_sin_asignacion              boolean,
    feriado_trabajado_no_registrado     boolean,
    feriado_especial_no_registrado      boolean,
    descanso_no_asignado                boolean,
    dia_trabajado_sin_turno             boolean,
    -- Placeholders (requieren columnas area/subturno en turnos_personal — Etapa 4+)
    doble_turno_no_registrado           boolean,
    medio_turno_extra_no_registrado     boolean,
    semana_desbalanceada                boolean,
    -- Sugerencia operativa principal
    sugerencia                          text
)
LANGUAGE sql
STABLE
AS $$
WITH
-- Calendario: un registro por día dentro del rango pedido
cal AS (
    SELECT gs::date AS fecha
    FROM generate_series(p_desde, p_hasta, interval '1 day') AS gs
),

-- Empleados activos solamente
emp AS (
    SELECT
        e.id                        AS empleado_id,
        e.nombre                    AS empleado_nombre,
        e.activo                    AS empleado_activo,
        e.modalidad,
        e.tipo_relacion,
        e.asignacion_principal,
        e.asignacion_secundaria_1,
        e.asignacion_secundaria_2,
        e.descanso_habitual,
        e.descanso_alternativo
    FROM public.empleados e
    WHERE e.activo = true
),

-- Grilla base: empleados activos × todos los días del rango
grilla AS (
    SELECT
        e.*,
        c.fecha,
        -- dow (0=domingo .. 6=sábado) — estándar PostgreSQL EXTRACT(DOW)
        EXTRACT(DOW FROM c.fecha)::int                              AS dow,
        -- Nombre del día en español (sin tilde, independiente del locale)
        CASE EXTRACT(ISODOW FROM c.fecha)::int
            WHEN 1 THEN 'lunes'
            WHEN 2 THEN 'martes'
            WHEN 3 THEN 'miercoles'
            WHEN 4 THEN 'jueves'
            WHEN 5 THEN 'viernes'
            WHEN 6 THEN 'sabado'
            WHEN 7 THEN 'domingo'
        END                                                         AS dia_semana_txt
    FROM emp e
    CROSS JOIN cal c
),

-- Unir con todas las tablas auxiliares
datos AS (
    SELECT
        g.*,

        -- Turno del día (puede ser NULL si no hay registro)
        tp.id           AS turno_id,
        tp.tipo_turno,
        tp.estado,
        tp.observacion,

        -- Disponibilidad declarada del empleado para ese día de semana
        ed.turno        AS disponibilidad_turno,

        -- Turno fijo (si aplica)
        etf.tipo        AS turno_fijo_tipo,

        -- Feriado del día (puede ser NULL)
        f.id            AS feriado_id,
        f.descripcion   AS feriado_descripcion,
        COALESCE(f.es_especial, false)      AS es_especial,
        (f.id IS NOT NULL)                  AS es_feriado,

        -- Feriado especial asignado a este empleado en el año correspondiente
        (er.id IS NOT NULL)                 AS feriado_especial_asignado

    FROM grilla g

    LEFT JOIN public.turnos_personal tp
           ON tp.empleado_id = g.empleado_id
          AND tp.fecha        = g.fecha

    -- dia_semana_txt se normalizó arriba; debe coincidir con los valores
    -- guardados en empleado_disponibilidad.dia_semana
    LEFT JOIN public.empleado_disponibilidad ed
           ON ed.empleado_id  = g.empleado_id
          AND ed.dia_semana   = g.dia_semana_txt

    LEFT JOIN public.empleado_turno_fijo etf
           ON etf.empleado_id = g.empleado_id

    LEFT JOIN public.feriados f
           ON f.fecha = g.fecha

    LEFT JOIN public.especial_rotacion er
           ON er.empleado_id  = g.empleado_id
          AND er.feriado_id   = f.id
          AND er.anio         = EXTRACT(YEAR FROM g.fecha)::int
),

-- Calcular flags derivados
flags AS (
    SELECT
        d.*,

        -- ¿Realizó trabajo real? (estado presente y no es ausencia/descanso)
        CASE
            WHEN d.estado IS NOT NULL
             AND d.estado NOT IN ('franco', 'vacaciones', 'enfermo', 'falta')
            THEN true
            ELSE false
        END AS turno_realizado_c,

        -- Horas estimadas según tipo_turno
        -- maniana/tarde: 6 h (turno parcial); mixto/partido: 8 h (turno completo).
        -- Estos valores son los mismos usados en view_turnos_resumen_mensual_v3
        -- y sirven como base para el cálculo de equivalencias de jornal en v4.
        CASE
            WHEN d.tipo_turno = 'maniana' THEN 6
            WHEN d.tipo_turno = 'tarde'   THEN 6
            WHEN d.tipo_turno = 'mixto'   THEN 8
            WHEN d.tipo_turno = 'partido' THEN 8
            ELSE 0
        END AS horas_normales_c

    FROM datos d
),

-- Validaciones operativas
valids AS (
    SELECT
        fv.*,

        -- No hay ningún registro en turnos_personal para ese (empleado, fecha)
        (fv.turno_id IS NULL)   AS persona_sin_asignacion_c,

        -- Feriado normal trabajado pero sin registro en feriado_trabajado
        CASE
            WHEN fv.es_feriado = true
             AND fv.es_especial = false
             AND fv.turno_realizado_c = true
             AND NOT EXISTS (
                 SELECT 1
                 FROM public.feriado_trabajado ft
                 WHERE ft.empleado_id = fv.empleado_id
                   AND ft.feriado_id  = fv.feriado_id
             )
            THEN true
            ELSE false
        END AS feriado_trabajado_no_registrado_c,

        -- Feriado especial trabajado pero sin registro en feriado_especial_trabajado
        CASE
            WHEN fv.es_feriado = true
             AND fv.es_especial = true
             AND fv.turno_realizado_c = true
             AND NOT EXISTS (
                 SELECT 1
                 FROM public.feriado_especial_trabajado fe
                 WHERE fe.empleado_id = fv.empleado_id
                   AND fe.feriado_id  = fv.feriado_id
             )
            THEN true
            ELSE false
        END AS feriado_especial_no_registrado_c,

        -- Hay registro pero el estado no corresponde a ninguna ausencia válida
        -- y no hubo trabajo real (ej: estado 'compensado' sin tipo_turno real)
        CASE
            WHEN fv.turno_realizado_c = false
             AND fv.estado IS NOT NULL
             AND fv.estado NOT IN ('franco', 'vacaciones', 'enfermo', 'falta', 'compensado')
            THEN true
            ELSE false
        END AS descanso_no_asignado_c,

        -- Hay trabajo real pero tipo_turno es NULL (no debería ocurrir con el esquema actual)
        CASE
            WHEN fv.turno_realizado_c = true AND fv.tipo_turno IS NULL
            THEN true
            ELSE false
        END AS dia_trabajado_sin_turno_c

    FROM flags fv
)

-- Proyección final
SELECT
    -- Empleado
    v.empleado_id,
    v.empleado_nombre,
    v.empleado_activo,
    v.modalidad,
    v.tipo_relacion,
    v.asignacion_principal,
    v.asignacion_secundaria_1,
    v.asignacion_secundaria_2,
    v.descanso_habitual,
    v.descanso_alternativo,
    -- Calendario
    v.fecha,
    v.dow,
    v.dia_semana_txt                                AS dia_semana,
    -- Turno
    v.turno_id,
    v.tipo_turno,
    v.estado,
    v.observacion,
    v.turno_realizado_c                             AS turno_realizado,
    v.horas_normales_c                              AS horas_normales,
    -- Disponibilidad / turno fijo
    v.disponibilidad_turno,
    v.turno_fijo_tipo,
    -- Feriados
    v.es_feriado,
    v.es_especial,
    v.feriado_id,
    v.feriado_descripcion,
    v.feriado_especial_asignado,
    -- Validaciones operativas
    v.persona_sin_asignacion_c                      AS persona_sin_asignacion,
    v.feriado_trabajado_no_registrado_c             AS feriado_trabajado_no_registrado,
    v.feriado_especial_no_registrado_c              AS feriado_especial_no_registrado,
    v.descanso_no_asignado_c                        AS descanso_no_asignado,
    v.dia_trabajado_sin_turno_c                     AS dia_trabajado_sin_turno,
    -- Placeholders hasta Etapa 4 (requieren columnas area/subturno en turnos_personal)
    false                                           AS doble_turno_no_registrado,
    false                                           AS medio_turno_extra_no_registrado,
    false                                           AS semana_desbalanceada,
    -- Sugerencia operativa principal (orden de prioridad alineado con v3)
    CASE
        WHEN v.feriado_trabajado_no_registrado_c  = true THEN 'registrar_feriado_trabajado'
        WHEN v.feriado_especial_no_registrado_c   = true THEN 'registrar_feriado_especial'
        WHEN v.dia_trabajado_sin_turno_c          = true THEN 'asignar_turno'
        WHEN v.persona_sin_asignacion_c           = true THEN 'asignar_turno'
        WHEN v.descanso_no_asignado_c             = true THEN 'asignar_turno'
        ELSE null
    END                                             AS sugerencia

FROM valids v
ORDER BY v.fecha, v.empleado_id;
$$;
