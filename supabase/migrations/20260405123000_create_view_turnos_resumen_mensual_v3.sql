CREATE OR REPLACE VIEW public.view_turnos_resumen_mensual_v3 AS
WITH base AS (
    SELECT
        tp.empleado_id,
        tp.fecha,
        tp.tipo_turno,
        tp.estado,
        tp.observacion,

        -- Flag básico: ¿hubo trabajo real?
        (tp.estado NOT IN ('franco','descanso','vacaciones','enfermo','falta')) AS turno_realizado,

        -- Horas normales (placeholder)
        CASE 
            WHEN tp.tipo_turno = 'maniana' THEN 6
            WHEN tp.tipo_turno = 'tarde' THEN 6
            WHEN tp.tipo_turno = 'mixto' THEN 8
            WHEN tp.tipo_turno = 'partido' THEN 8
            ELSE 0
        END AS horas_normales,

        -- Horas extra (sin subturno → siempre 0)
        0 AS horas_extra
    FROM public.turnos_personal tp
),

feriados AS (
    SELECT
        b.*,
        f.id AS feriado_id,
        f.es_especial,
        (f.id IS NOT NULL) AS es_feriado
    FROM base b
    LEFT JOIN public.feriados f
        ON f.fecha = b.fecha
),

feriados_validacion AS (
    SELECT
        f.*,

        -- Feriado normal trabajado sin registrar
        CASE 
            WHEN f.es_feriado = TRUE
             AND f.es_especial = FALSE
             AND f.turno_realizado = TRUE
             AND NOT EXISTS (
                 SELECT 1 
                 FROM public.feriado_trabajado ft
                 WHERE ft.empleado_id = f.empleado_id
                 AND ft.feriado_id = f.feriado_id
             )
            THEN TRUE ELSE FALSE
        END AS feriado_trabajado_no_registrado,

        -- Feriado especial trabajado sin registrar
        CASE 
            WHEN f.es_feriado = TRUE
             AND f.es_especial = TRUE
             AND f.turno_realizado = TRUE
             AND NOT EXISTS (
                 SELECT 1 
                 FROM public.feriado_especial_trabajado fe
                 WHERE fe.empleado_id = f.empleado_id
                 AND fe.feriado_id = f.feriado_id
             )
            THEN TRUE ELSE FALSE
        END AS feriado_especial_no_registrado
    FROM feriados f
),

validaciones_final AS (
    SELECT
        v.*,

        -- Descanso no asignado
        CASE 
            WHEN v.turno_realizado = FALSE
             AND v.estado NOT IN ('franco','descanso','vacaciones','enfermo')
            THEN TRUE ELSE FALSE
        END AS descanso_no_asignado,

        -- Día trabajado sin turno
        CASE 
            WHEN v.turno_realizado = TRUE
             AND v.tipo_turno IS NULL
            THEN TRUE ELSE FALSE
        END AS dia_trabajado_sin_turno,

        -- Doble turno no registrado (sin subturno → siempre FALSE)
        FALSE AS doble_turno_no_registrado,

        -- Medio turno extra no registrado (sin subturno → siempre FALSE)
        FALSE AS medio_turno_extra_no_registrado,

        -- Semana desbalanceada (placeholder)
        FALSE AS semana_desbalanceada
    FROM feriados_validacion v
),

sugerencias AS (
    SELECT
        vf.*,

        CASE
            -- PRIORIDAD 1: críticas
            WHEN vf.semana_desbalanceada = TRUE THEN 'sugerir_descanso_obligatorio'
            WHEN vf.feriado_trabajado_no_registrado = TRUE THEN 'registrar_feriado_trabajado'
            WHEN vf.feriado_especial_no_registrado = TRUE THEN 'registrar_feriado_especial'
            WHEN vf.dia_trabajado_sin_turno = TRUE THEN 'asignar_turno'

            -- PRIORIDAD 2: operativas fuertes (sin área → no aplican)
            -- PRIORIDAD 3: reasignación (sin área → no aplican)
            -- PRIORIDAD 4: apoyo (sin área → no aplican)

            -- PRIORIDAD 5: disponibilidad
            WHEN vf.turno_realizado = FALSE
             AND vf.estado NOT IN ('franco','descanso','vacaciones','enfermo')
            THEN 'asignar_turno'

            ELSE NULL
        END AS sugerencia

    FROM validaciones_final vf
)

SELECT * FROM sugerencias;
