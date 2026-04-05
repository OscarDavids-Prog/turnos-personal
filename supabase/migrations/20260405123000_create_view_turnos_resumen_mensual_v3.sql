CREATE OR REPLACE VIEW public.view_turnos_resumen_mensual_v3 AS
WITH base AS (
    SELECT
        tp.empleado_id,
        tp.fecha,
        tp.tipo_turno,
        tp.estado,
        tp.area,
        tp.subturno,
        tp.observacion,

        -- Flags básicos
        (tp.estado NOT IN ('franco','descanso','vacaciones','enfermo','falta')) AS turno_realizado,

        -- Horas normales (placeholder)
        CASE 
            WHEN tp.tipo_turno = 'maniana' THEN 6
            WHEN tp.tipo_turno = 'tarde' THEN 6
            WHEN tp.tipo_turno = 'mixto' THEN 8
            WHEN tp.tipo_turno = 'partido' THEN 8
            ELSE 0
        END AS horas_normales,

        -- Horas extra (placeholder)
        CASE 
            WHEN tp.subturno = 'medio_extra' THEN 4
            WHEN tp.subturno = 'doble' THEN 8
            ELSE 0
        END AS horas_extra
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
                 SELECT 1 FROM public.feriado_trabajado ft
                 WHERE ft.empleado_id = f.empleado_id
                 AND ft.fecha = f.fecha
             )
            THEN TRUE ELSE FALSE
        END AS feriado_trabajado_no_registrado,

        -- Feriado especial trabajado sin registrar
        CASE 
            WHEN f.es_feriado = TRUE
             AND f.es_especial = TRUE
             AND f.turno_realizado = TRUE
             AND NOT EXISTS (
                 SELECT 1 FROM public.feriado_especial_trabajado fe
                 WHERE fe.empleado_id = f.empleado_id
                 AND fe.fecha = f.fecha
             )
            THEN TRUE ELSE FALSE
        END AS feriado_especial_no_registrado
    FROM feriados f
),

conteo_area AS (
    SELECT
        fecha,
        area,
        COUNT(*) AS cantidad,
        COUNT(*) FILTER (WHERE subturno = 'intermedio') AS intermedios,
        COUNT(*) FILTER (WHERE tipo_turno = 'maniana') AS maniana,
        COUNT(*) FILTER (WHERE tipo_turno = 'tarde') AS tarde
    FROM public.turnos_personal
    GROUP BY fecha, area
),

validaciones_area AS (
    SELECT
        fv.*,
        ca.cantidad,
        ca.intermedios,
        ca.maniana,
        ca.tarde,

        -- Persona sin asignación
        CASE 
            WHEN fv.turno_realizado = FALSE
             AND fv.estado NOT IN ('franco','descanso')
            THEN TRUE ELSE FALSE
        END AS persona_sin_asignacion,

        -- Exceso de personal
        CASE 
            WHEN fv.area = 'lavadero' AND ca.cantidad > 4 THEN TRUE
            WHEN fv.area = 'plancha' AND ca.cantidad > 7 THEN TRUE
            WHEN fv.area = 'toallas' AND ca.cantidad > 3 THEN TRUE
            ELSE FALSE
        END AS exceso_personal,

        -- Falta intermedio en lavadero cuando hay 3
        CASE 
            WHEN fv.area = 'lavadero'
             AND ca.cantidad = 3
             AND ca.intermedios = 0
            THEN TRUE ELSE FALSE
        END AS falta_intermedio,

        -- Intermedio fuera de lugar
        CASE 
            WHEN fv.area = 'lavadero'
             AND ca.cantidad = 4
             AND ca.intermedios > 0
            THEN TRUE ELSE FALSE
        END AS intermedio_fuera_de_lugar,

        -- Distribución incorrecta mañana/tarde
        CASE 
            WHEN fv.area = 'lavadero'
             AND ca.cantidad = 4
             AND NOT (ca.maniana = 2 AND ca.tarde = 2)
            THEN TRUE ELSE FALSE
        END AS distribucion_incorrecta,

        -- Polivalencia inválida
        CASE 
            WHEN fv.area = 'reparto' AND fv.subturno NOT IN ('partido','unico')
            THEN TRUE ELSE FALSE
        END AS polivalencia_invalida

    FROM feriados_validacion fv
    LEFT JOIN conteo_area ca
        ON ca.fecha = fv.fecha
        AND ca.area = fv.area
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

        -- Doble turno no registrado
        CASE 
            WHEN v.subturno = 'doble'
             AND v.horas_extra = 0
            THEN TRUE ELSE FALSE
        END AS doble_turno_no_registrado,

        -- Medio turno extra no registrado
        CASE 
            WHEN v.subturno = 'medio_extra'
             AND v.horas_extra = 0
            THEN TRUE ELSE FALSE
        END AS medio_turno_extra_no_registrado,

        -- Semana desbalanceada (placeholder)
        FALSE AS semana_desbalanceada
    FROM validaciones_area v
),

sugerencias AS (
    SELECT
        vf.*,

        CASE
            -- PRIORIDAD 1: críticas
            WHEN vf.semana_desbalanceada = TRUE THEN 'sugerir_descanso_obligatorio'
            WHEN vf.feriado_trabajado_no_registrado = TRUE THEN 'registrar_feriado_trabajado'
            WHEN vf.feriado_especial_no_registrado = TRUE THEN 'registrar_feriado_especial'
            WHEN vf.doble_turno_no_registrado = TRUE THEN 'registrar_doble_turno'
            WHEN vf.medio_turno_extra_no_registrado = TRUE THEN 'registrar_medio_extra'

            -- PRIORIDAD 2: operativas fuertes
            WHEN vf.area = 'lavadero' AND vf.cantidad < 3 THEN 'refuerzo_lavadero'
            WHEN vf.area = 'plancha' AND vf.maniana < 3 THEN 'refuerzo_plancha_maniana'
            WHEN vf.area = 'plancha' AND vf.tarde < 4 THEN 'refuerzo_plancha_tarde'
            WHEN vf.area = 'toallas' AND vf.cantidad < 2 THEN 'refuerzo_toallas'

            -- PRIORIDAD 3: reasignación
            WHEN vf.area = 'plancha' AND vf.maniana = 4 AND vf.tarde = 2 THEN 'reasignar_plancha_tarde'
            WHEN vf.area = 'lavadero' AND vf.intermedio_fuera_de_lugar = TRUE THEN 'reorganizar_lavadero'

            -- PRIORIDAD 4: apoyo
            WHEN vf.area = 'guardapolvos' AND vf.turno_realizado = FALSE THEN 'apoyo_lavadero'
            WHEN vf.area = 'desmanche' AND vf.turno_realizado = FALSE THEN 'apoyo_guardapolvos'

            -- PRIORIDAD 5: disponibilidad
            WHEN vf.persona_sin_asignacion = TRUE THEN 'asignar_turno'

            ELSE NULL
        END AS sugerencia

    FROM validaciones_final vf
)

SELECT * FROM sugerencias;
