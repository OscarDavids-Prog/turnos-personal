CREATE OR REPLACE VIEW public.view_turnos_resumen_mensual_v2 AS
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

        -- Horas normales (placeholder, ajustar según reglas reales)
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

-- Conteo por área y día
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

-- Validaciones por área (alertas NO bloqueantes)
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

        -- Exceso de personal (alerta)
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

        -- Intermedio fuera de lugar (lavadero con 4)
        CASE 
            WHEN fv.area = 'lavadero'
             AND ca.cantidad = 4
             AND ca.intermedios > 0
            THEN TRUE ELSE FALSE
        END AS intermedio_fuera_de_lugar,

        -- Distribución incorrecta mañana/tarde (lavadero con 4)
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

-- Validaciones críticas
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
)

SELECT * FROM validaciones_final;
