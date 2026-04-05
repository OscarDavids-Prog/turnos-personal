CREATE OR REPLACE VIEW public.view_turnos_resumen_empleado_mensual_v5 AS
WITH v4 AS (
    SELECT *
    FROM public.view_turnos_resumen_mensual_v4
),

base AS (
    SELECT
        empleado_id,
        date_trunc('month', fecha) AS mes,

        -- Totales ya calculados en V4
        MAX(jornal_total_mes) AS jornal_total_mes,
        MAX(jornal_extra_mes) AS jornal_extra_mes,
        MAX(jornal_normal_mes) AS jornal_normal_mes,
        MAX(jornal_feriado_mes) AS jornal_feriado_mes,
        MAX(jornal_especial_mes) AS jornal_especial_mes,

        -- Días trabajados (equivalente > 0)
        SUM(CASE WHEN jornal_equivalente > 0 THEN 1 ELSE 0 END) AS dias_trabajados,

        -- Descansos
        SUM(CASE WHEN jornal_equivalente = 0 THEN 1 ELSE 0 END) AS dias_descanso,

        -- Licencias
        SUM(CASE WHEN tipo_equivalencia = 'licencia' THEN 1 ELSE 0 END) AS dias_licencia,

        -- Flags mensuales
        BOOL_OR(requiere_compensacion) AS requiere_compensacion_mes,
        BOOL_OR(requiere_liquidacion) AS requiere_liquidacion_mes,
        BOOL_OR(requiere_revision) AS requiere_revision_mes
    FROM v4
    GROUP BY empleado_id, date_trunc('month', fecha)
)
SELECT
    b.empleado_id,
    e.nombre,
    b.mes,

    -- Totales del mes
    b.jornal_total_mes,
    b.jornal_extra_mes,
    b.jornal_normal_mes,
    b.jornal_feriado_mes,
    b.jornal_especial_mes,

    -- Cantidades de días
    b.dias_trabajados,
    b.dias_descanso,
    b.dias_licencia,

    -- Flags mensuales
    b.requiere_compensacion_mes,
    b.requiere_liquidacion_mes,
    b.requiere_revision_mes

FROM base b
LEFT JOIN public.empleados e ON e.id = b.empleado_id

ORDER BY b.empleado_id, b.mes;
