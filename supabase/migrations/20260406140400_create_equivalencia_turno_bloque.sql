-- Equivalencias de cobertura por tipo de turno
-- Define cuánto aporta cada tipo_turno a cada bloque (mañana / tarde).
--
-- Notas operativas:
--   mixto   = intermedio: mitad mañana + mitad tarde (1 jornal completo).
--   partido = aplica solo a mostrador; igual distribución que mixto pero con
--             semántica operativa diferente (2 empleados cubren el área completa).
--   libre / no_asignado = no aportan cobertura.
--
-- Idempotente: crea tabla y seed solo si no existen.

CREATE TABLE IF NOT EXISTS public.equivalencia_turno_bloque (
    tipo_turno      TEXT    PRIMARY KEY,
    aporte_maniana  NUMERIC NOT NULL,
    aporte_tarde    NUMERIC NOT NULL,
    jornal_total    NUMERIC NOT NULL,

    CONSTRAINT equivalencia_tipo_check CHECK (
        tipo_turno IN ('maniana', 'tarde', 'mixto', 'partido', 'libre', 'no_asignado')
    ),
    CONSTRAINT equivalencia_aporte_maniana_check CHECK (aporte_maniana >= 0),
    CONSTRAINT equivalencia_aporte_tarde_check   CHECK (aporte_tarde   >= 0),
    CONSTRAINT equivalencia_jornal_check         CHECK (jornal_total   >= 0)
);

-- Seed: insertar/actualizar valores oficiales de equivalencia
INSERT INTO public.equivalencia_turno_bloque
    (tipo_turno, aporte_maniana, aporte_tarde, jornal_total)
VALUES
    -- jornada completa: cubre bloque mañana (1 jornal)
    ('maniana',     1.0, 0.0, 1.0),
    -- jornada completa: cubre bloque tarde (1 jornal)
    ('tarde',       0.0, 1.0, 1.0),
    -- intermedio: mitad mañana + mitad tarde (1 jornal) — alias operativo: mixto == intermedio
    ('mixto',       0.5, 0.5, 1.0),
    -- partido (mostrador): 0.5 mañana + 0.5 tarde = 1 jornal — aplica solo en mostrador
    ('partido',     0.5, 0.5, 1.0),
    -- libre: no aporta cobertura
    ('libre',       0.0, 0.0, 0.0),
    -- no asignado: no aporta cobertura
    ('no_asignado', 0.0, 0.0, 0.0)
ON CONFLICT (tipo_turno) DO UPDATE
    SET aporte_maniana = EXCLUDED.aporte_maniana,
        aporte_tarde   = EXCLUDED.aporte_tarde,
        jornal_total   = EXCLUDED.jornal_total;
