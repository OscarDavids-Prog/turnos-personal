CREATE OR REPLACE VIEW public.view_turnos_resumen_mensual_v4 AS
WITH v3 AS (
    SELECT *
    FROM public.view_turnos_resumen_mensual_v3
),

empleados AS (
    SELECT 
        e.id AS empleado_id,
        e.modalidad,
        e.tipo_relacion
    FROM public.empleados e
),

base AS (
    SELECT
        v3.*,
        emp.modalidad,
        emp.tipo_relacion,

        -- Flags de tipo de empleado
        (emp.modalidad = 'sueldo' OR emp.tipo_relacion = 'mensual') AS es_mensual,
        (emp.modalidad = 'jornal' OR emp.tipo_relacion = 'jornal') AS es_jornalizado
    FROM v3
    LEFT JOIN empleados emp ON emp.empleado_id = v3.empleado_id
),

equivalencias AS (
    SELECT
        b.*,

        -- Tipo de equivalencia (sin subturno, sin área)
        CASE
            WHEN b.feriado_especial_no_registrado = TRUE THEN 'feriado_especial'
            WHEN b.feriado_trabajado_no_registrado = TRUE THEN 'feriado'
            WHEN b.estado IN ('vacaciones','enfermo') THEN 'licencia'
            WHEN b.turno_realizado = TRUE THEN 'normal'
            ELSE 'descanso'
        END AS tipo_equivalencia,

        -- Jornal equivalente
        CASE
            WHEN b.feriado_especial_no_registrado = TRUE THEN 2.5
            WHEN b.feriado_trabajado_no_registrado = TRUE THEN 2
            WHEN b.estado IN ('vacaciones','enfermo') THEN 1
            WHEN b.turno_realizado = TRUE THEN 1
            ELSE 0
        END AS jornal_equivalente,

        -- Jornal extra (solo excedente)
        CASE
            WHEN b.feriado_especial_no_registrado = TRUE AND b.es_mensual THEN 1.5
            WHEN b.feriado_especial_no_registrado = TRUE AND b.es_jornalizado THEN 2.5

            WHEN b.feriado_trabajado_no_registrado = TRUE AND b.es_mensual THEN 1
            WHEN b.feriado_trabajado_no_registrado = TRUE AND b.es_jornalizado THEN 2

            ELSE 0
        END AS jornal_extra
    FROM base b
),

acumulados AS (
    SELECT
        e.*,

        -- Acumulado semanal
        SUM(e.jornal_equivalente) OVER (
            PARTITION BY e.empleado_id, date_trunc('week', e.fecha)
            ORDER BY e.fecha
        ) AS acumulado_semana,

        -- Acumulado mensual
        SUM(e.jornal_equivalente) OVER (
            PARTITION BY e.empleado_id, date_trunc('month', e.fecha)
        ) AS acumulado_mes
    FROM equivalencias e
),

totales_mensuales AS (
    SELECT
        a.*,

        -- Total de jornales del mes
        SUM(a.jornal_equivalente) OVER (
            PARTITION BY a.empleado_id, date_trunc('month', a.fecha)
        ) AS jornal_total_mes,

        -- Total de jornal extra del mes
        SUM(a.jornal_extra) OVER (
            PARTITION BY a.empleado_id, date_trunc('month', a.fecha)
        ) AS jornal_extra_mes,

        -- Total de días normales
        SUM(
            CASE WHEN a.tipo_equivalencia = 'normal' THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY a.empleado_id, date_trunc('month', a.fecha)
        ) AS jornal_normal_mes,

        -- Total de feriados trabajados
        SUM(
            CASE WHEN a.tipo_equivalencia = 'feriado' THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY a.empleado_id, date_trunc('month', a.fecha)
        ) AS jornal_feriado_mes,

        -- Total de feriados especiales trabajados
        SUM(
            CASE WHEN a.tipo_equivalencia = 'feriado_especial' THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY a.empleado_id, date_trunc('month', a.fecha)
        ) AS jornal_especial_mes
    FROM acumulados a
)

SELECT *
FROM totales_mensuales
ORDER BY empleado_id, fecha;
