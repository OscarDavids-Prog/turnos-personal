# Release Notes — 2026-04-06 (Etapa 4)

## Etapa 4 completada: Normalización + Matrices de dotación + Equivalencias

**Fecha:** 2026-04-06
**Issue:** [#20](https://github.com/OscarDavids-Prog/turnos-personal/issues/20)
**Tipo:** Migraciones SQL + documentación

---

### Qué se hizo

Se completó la **Etapa 4 (Normalización + Matrices de dotación + Equivalencias)** del módulo de turnos personal.

---

### Cambios incluidos

#### Nuevas migraciones de base de datos

- **`20260406140000_create_dias_semana.sql`**
  - Crea `public.dias_semana` con `id smallint` (1..7) y `nombre text`.
  - Seed: lunes(1), martes(2), miercoles(3), jueves(4), viernes(5), sabado(6), domingo(7).

- **`20260406140100_create_areas_turnos.sql`**
  - Crea `public.areas_turnos` con `id bigserial`, `codigo text unique`, `nombre text unique`, `activa boolean`, `orden int`.
  - Seed: lavadero, plancha, pr_persona, pr_delantales, toallas, desmanche, reparto, mostrador, mantenimiento.

- **`20260406140200_normalizar_empleados_fk.sql`**
  - Agrega columnas FK en `public.empleados`:
    - `asignacion_principal_area_id bigint NOT NULL` → FK a `areas_turnos`.
    - `asignacion_secundaria_1_area_id bigint NULL` → FK a `areas_turnos`.
    - `asignacion_secundaria_2_area_id bigint NULL` → FK a `areas_turnos`.
    - `descanso_habitual_dia smallint NULL` → FK a `dias_semana`.
    - `descanso_alternativo_dia smallint NULL` → FK a `dias_semana`.
  - Backfill condicional desde columnas TEXT legacy (si hubiera datos).
  - Agrega constraints de consistencia:
    - `chk_empleados_sec1_ne_principal`: secundaria_1 ≠ principal.
    - `chk_empleados_sec2_ne_principal`: secundaria_2 ≠ principal.
    - `chk_empleados_sec2_ne_sec1`: secundaria_2 ≠ secundaria_1.
    - `chk_empleados_descanso_alt_ne_hab`: descanso alternativo ≠ habitual.
  - Elimina columnas TEXT legacy: `asignacion_principal`, `asignacion_secundaria_1`, `asignacion_secundaria_2`, `descanso_habitual`, `descanso_alternativo`.

- **`20260406140300_create_dotacion_area_bloque_config.sql`**
  - Crea `public.dotacion_area_bloque_config` con:
    - `area_id` FK a `areas_turnos`, `dia` FK a `dias_semana`, `bloque` ('maniana'|'tarde').
    - `min_recomendado`, `max_recomendado`, `min_intermedios`, `max_intermedios`.
    - UNIQUE `(area_id, dia, bloque)`.
  - Índice de soporte en `area_id`.

- **`20260406140400_create_equivalencia_turno_bloque.sql`**
  - Crea `public.equivalencia_turno_bloque` con `tipo_turno PK`, `aporte_maniana`, `aporte_tarde`, `jornal_total`.
  - Seed oficial con `ON CONFLICT DO UPDATE` (idempotente):
    - `maniana`: 1.0, 0.0, 1.0
    - `tarde`: 0.0, 1.0, 1.0
    - `mixto`: 0.5, 0.5, 1.0 (**alias operativo: mixto == intermedio**)
    - `partido`: 0.5, 0.5, 1.0 (aplica solo en **mostrador**)
    - `libre`: 0.0, 0.0, 0.0
    - `no_asignado`: 0.0, 0.0, 0.0

#### Nueva documentación

- **`docs/etapa4_normalizacion.md`**
  - Catálogo de áreas y días: estructura, cómo se usa en UI por empleado.
  - Asignaciones y descansos: columnas nuevas, columnas eliminadas, constraints.
  - Matriz min/max por área/día/bloque: estructura y semántica.
  - Equivalencias de cobertura: tabla completa, nota sobre `mixto == intermedio`, nota sobre `partido` en mostrador.
  - Vista de día completo: mockup y pseudocódigo SQL del cálculo de cobertura.
  - **Nota operativa:** sistema vivo, advertencias no bloqueantes.

---

### Nota operativa

> ⚠️ **Sistema vivo:** las validaciones de dotación y cobertura **advierten y sugieren**, pero **nunca bloquean** la operación. El operador puede registrar o modificar cualquier turno independientemente de las advertencias.

---

### Estado del plan maestro

| Etapa | Descripción | Estado |
|-------|-------------|--------|
| 1 | Análisis profundo de migraciones | ✅ Completada |
| 2 | Diseño de `fn_turnos_semana` | ✅ Completada |
| 3 | Migración SQL a Supabase | ✅ Completada |
| **4** | **Normalización FK áreas/días + matriz dotación** | **✅ Completada** |
| 5 | Implementación recomendaciones inteligentes | ⬜ Pendiente |
| 6 | Wireframe Flutter + estructura | ⬜ Pendiente |
| 7 | Documentación y cierre | ⬜ Pendiente |
