# Release Notes — 2026-04-06

## Etapa 2 completada: Diseño de `public.fn_turnos_semana`

**Fecha:** 2026-04-06
**Issue:** [#20](https://github.com/OscarDavids-Prog/turnos-personal/issues/20)
**Tipo:** Documentación de diseño (sin cambios de BD)

---

### Qué se hizo

Se completó la **Etapa 2 (Diseño)** del módulo de turnos personal, dejando registrada la decisión arquitectónica y el contrato completo de la función parametrizada semanal.

### Cambios incluidos

- **Nuevo documento:** `docs/ETAPA_2_DISENO_FN_TURNOS_SEMANA.md`
  - Decisión: usar `public.fn_turnos_semana(desde date, hasta date)` en lugar de una vista fija, para permitir consultas por rango de fechas desde Flutter.
  - Contrato de salida: 31 columnas definidas con tipo, origen y descripción.
  - Diagrama de joins necesarios: `empleados`, `turnos_personal`, `feriados`, `feriado_trabajado`, `feriado_especial_trabajado`, `empleado_disponibilidad`, `empleado_turno_fijo`, `especial_rotacion`.
  - Alineación con `public.view_turnos_resumen_mensual_v3`: misma lógica de flags y sugerencias.
  - Ejemplos de queries SQL y código Dart/Flutter para consumo vía Supabase RPC.
  - Notas sobre RLS (pendiente etapa futura), bug conocido en migración `feriado_trabajado`, y placeholders para columnas que aún no existen.

### Lo que NO se implementó (scope de esta etapa)

- **No se creó** la función `fn_turnos_semana` en SQL.
- **No se agregó** ninguna migración de base de datos.
- **No se modificó** ninguna tabla ni vista existente.

La implementación SQL queda para **Etapa 3 — Migración**.

---

### Estado del plan maestro

| Etapa | Descripción | Estado |
|-------|-------------|--------|
| 1 | Análisis profundo de migraciones | ✅ Completada |
| **2** | **Diseño de `fn_turnos_semana`** | **✅ Completada** |
| 3 | Migración SQL a Supabase | ⬜ Pendiente |
| 4 | Implementación validaciones (area/subturno) | ⬜ Pendiente |
| 5 | Implementación recomendaciones inteligentes | ⬜ Pendiente |
| 6 | Wireframe Flutter + estructura | ⬜ Pendiente |
| 7 | Documentación y cierre | ⬜ Pendiente |
