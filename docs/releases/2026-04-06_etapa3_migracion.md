# Release Notes — 2026-04-06 (Etapa 3)

## Etapa 3 completada: Migración SQL — `public.fn_turnos_semana`

**Fecha:** 2026-04-06
**Issue:** [#20](https://github.com/OscarDavids-Prog/turnos-personal/issues/20)
**Tipo:** Nueva función SQL + documentación

---

### Qué se hizo

Se completó la **Etapa 3 (Migración SQL)** del módulo de turnos personal: se creó la función parametrizada semanal acordada en Etapa 2.

### Cambios incluidos

#### Nueva migración de base de datos

- **`supabase/migrations/20260406121957_create_fn_turnos_semana.sql`**
  - Implementa `public.fn_turnos_semana(p_desde date, p_hasta date)`.
  - Devuelve una grilla `empleados activos × calendario (generate_series)`.
  - LEFT JOINs a: `turnos_personal`, `feriados`, `feriado_trabajado`, `feriado_especial_trabajado`, `empleado_disponibilidad`, `empleado_turno_fijo`, `especial_rotacion`.
  - Normalización de `dia_semana`: valores en español sin tilde (`lunes`, `martes`, `miercoles`, `jueves`, `viernes`, `sabado`, `domingo`), usando `EXTRACT(ISODOW)` (independiente del locale).
  - Validaciones: `persona_sin_asignacion`, `feriado_trabajado_no_registrado`, `feriado_especial_no_registrado`, `descanso_no_asignado`, `dia_trabajado_sin_turno`.
  - Placeholders `false` para `doble_turno_no_registrado`, `medio_turno_extra_no_registrado`, `semana_desbalanceada` (Etapa 4+).
  - Columna `sugerencia` con prioridades: `registrar_feriado_trabajado` → `registrar_feriado_especial` → `asignar_turno` → NULL.
  - **Idempotente:** `CREATE OR REPLACE FUNCTION` es segura de re-ejecutar.

#### Nueva documentación

- **`docs/fn_turnos_semana.md`**
  - Descripción completa de la función: firma, columnas, joins, normalización de `dia_semana`.
  - Ejemplos de queries SQL y código Dart/Flutter para consumo vía Supabase RPC.
  - Ejemplo de output esperado.
  - Notas sobre RLS, idempotencia, placeholders y bug conocido en `feriado_trabajado`.

---

### Estado del plan maestro

| Etapa | Descripción | Estado |
|-------|-------------|--------|
| 1 | Análisis profundo de migraciones | ✅ Completada |
| 2 | Diseño de `fn_turnos_semana` | ✅ Completada |
| **3** | **Migración SQL a Supabase** | **✅ Completada** |
| 4 | Implementación validaciones (area/subturno) | ⬜ Pendiente |
| 5 | Implementación recomendaciones inteligentes | ⬜ Pendiente |
| 6 | Wireframe Flutter + estructura | ⬜ Pendiente |
| 7 | Documentación y cierre | ⬜ Pendiente |
