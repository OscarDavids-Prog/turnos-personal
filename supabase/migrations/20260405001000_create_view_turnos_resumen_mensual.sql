-- Vista de resumen mensual de turnos por empleado
-- Una fila por empleado por día

CREATE OR REPLACE VIEW public.view_turnos_resumen_mensual AS
WITH rangos AS (
    -- Rango de fechas global según turnos cargados
    SELECT 
        MIN(fecha) AS fecha_min,
        MAX(fecha) AS fecha_max
    FROM public.turnos_personal
),
calendario AS (
    -- Calendario diario global
    SELECT 
        gs::date AS fecha
    FROM rangos r,
         generate_series(r.fecha_min, r.fecha_max, interval '1 day') gs
),
empleados_activos AS (
    -- Empleados que tienen al menos un turno cargado
    SELECT DISTINCT e.id AS empleado_id
    FROM public.empleados e
    JOIN public.turnos_personal t ON t.empleado_id = e.id
),
base AS (
    -- Producto empleado x día
    SELECT 
        ea.empleado_id,
        c.fecha
    FROM empleados_activos ea
    CROSS JOIN calendario c
),
turnos AS (
    SELECT 
        t.empleado_id,
        t.fecha,
        t.tipo_turno,
        t.estado,
        t.observacion
    FROM public.turnos_personal t
),
feriados AS (
    SELECT 
        f.id AS feriado_id,
        f.fecha,
        f.descripcion,
        f.es_especial
    FROM public.feriados f
),
feriados_trabajados AS (
    SELECT 
        ft.empleado_id,
        ft.feriado_id,
        ft.fecha_trabajada
    FROM public.feriado_trabajado ft
),
feriados_especial_trabajados AS (
    SELECT 
        fe.empleado_id,
        fe.feriado_id,
        fe.fecha_trabajada
    FROM public.feriado_especial_trabajado fe
)
SELECT
    b.empleado_id,
    b.fecha,

    -- Datos de turno
    t.tipo_turno,
    COALESCE(t.estado, 'sin_registro') AS estado,
    t.observacion,

    -- Feriados
    (f.feriado_id IS NOT NULL) AS es_feriado,
    COALESCE(f.es_especial, false) AS es_especial,
    f.feriado_id,

    -- Turno realizado (versión 1, calculada simple)
    CASE
        WHEN t.estado = 'enfermo' THEN 'enfermo'
        WHEN t.estado = 'vacaciones' THEN 'vacaciones'
        WHEN t.estado = 'falta' THEN 'falta'
        WHEN t.estado = 'franco' THEN 'franco'
        WHEN t.estado = 'compensado' THEN 'compensado'
        WHEN t.tipo_turno IN ('maniana', 'tarde', 'mixto', 'partido') THEN 'normal'
        WHEN t.tipo_turno = 'libre' THEN 'libre'
        WHEN t.tipo_turno IS NULL THEN 'sin_turno'
        ELSE 'otro'
    END AS turno_realizado,

    -- Horas equivalentes (versión simple, ajustable luego)
    CASE
        WHEN t.estado IN ('enfermo', 'vacaciones', 'falta', 'franco', 'compensado') THEN 0
        WHEN t.tipo_turno IN ('maniana', 'tarde', 'mixto', 'partido') THEN 8
        ELSE 0
    END AS horas_normales,
    0::integer AS horas_extra, -- lo refinamos en iteración siguiente
    CASE
        WHEN t.estado IN ('enfermo', 'vacaciones', 'falta', 'franco', 'compensado') THEN 0
        WHEN t.tipo_turno IN ('maniana', 'tarde', 'mixto', 'partido') THEN 1
        ELSE 0
    END AS turnos_equivalentes,

    -- Integración con jornal / liquidación
    -- computa_jornal: día que genera derecho a jornal (jornalero)
    -- computa_sueldo: día que se computa en sueldo (mensualizado)
    -- requiere_liquidacion: hay algo que revisar (feriado, estado especial, etc.)
    CASE
        WHEN t.estado IN ('falta', 'enfermo', 'vacaciones', 'franco', 'compensado') THEN false
        WHEN t.tipo_turno IN ('maniana', 'tarde', 'mixto', 'partido') THEN true
        ELSE false
    END AS computa_jornal,
    true AS computa_sueldo, -- se puede refinar según tipo de empleado
    (
        (f.feriado_id IS NOT NULL AND t.tipo_turno IS NOT NULL)
        OR t.estado IN ('falta', 'enfermo', 'vacaciones', 'franco', 'compensado')
    ) AS requiere_liquidacion,

    -- Flags de control / posibles errores
    -- feriado_trabajado_no_registrado: trabajó feriado y no está en feriado_trabajado/especial
    CASE
        WHEN f.feriado_id IS NOT NULL
             AND t.tipo_turno IS NOT NULL
             AND ft.empleado_id IS NULL
             AND fe.empleado_id IS NULL
        THEN true
        ELSE false
    END AS feriado_trabajado_no_registrado,

    -- feriado_especial_no_registrado: especial + trabajado + no registrado
    CASE
        WHEN f.es_especial = true
             AND t.tipo_turno IS NOT NULL
             AND fe.empleado_id IS NULL
        THEN true
        ELSE false
    END AS feriado_especial_no_registrado

FROM base b
LEFT JOIN turnos t
    ON t.empleado_id = b.empleado_id
   AND t.fecha = b.fecha
LEFT JOIN feriados f
    ON f.fecha = b.fecha
LEFT JOIN feriados_trabajados ft
    ON ft.empleado_id = b.empleado_id
   AND ft.fecha_trabajada = b.fecha
LEFT JOIN feriados_especial_trabajados fe
    ON fe.empleado_id = b.empleado_id
   AND fe.fecha_trabajada = b.fecha;
