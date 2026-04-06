# Etapa 2 — Diseño: `public.fn_turnos_semana(desde date, hasta date)`

> **Issue de referencia:** [#20](https://github.com/OscarDavids-Prog/turnos-personal/issues/20)
> **Fecha de decisión:** 2026-04-06
> **Etapa:** 2 de 7 (Diseño)
> **Estado:** ✅ Documentado — pendiente implementación (Etapa 3)

---

## 1. Decisión de diseño

### Por qué función y no vista

La vista `public.view_turnos_resumen_mensual_v3` (y su variante v4) es excelente para el resumen mensual porque no necesita parámetros: siempre abarca un mes calendario completo.

Para la **grilla semanal** que consume Flutter, la semana visible cambia constantemente (el usuario navega semana a semana). Una vista fija no puede recibir el rango de fechas como parámetro, lo que forzaría a filtrar fuera de la base de datos o a descargar más datos de los necesarios.

**Decisión: implementar `public.fn_turnos_semana(desde date, hasta date)` como función que retorna tabla (RETURNS TABLE ...).**

Ventajas:
- Flutter pasa exactamente el rango a consultar.
- La función genera el calendario internamente con `generate_series(desde, hasta, '1 day')`.
- Misma lógica de validaciones que v3, reutilizando el mismo patrón de CTEs.
- El contrato de columnas es estable y versionable.

---

## 2. Contrato de salida

La función retorna una fila por cada combinación `(empleado_id, fecha)` dentro del rango `[desde, hasta]`.

### Columnas retornadas

| Columna | Tipo PostgreSQL | Origen | Descripción |
|---|---|---|---|
| `empleado_id` | `BIGINT` | `empleados.id` | Identificador del empleado |
| `empleado_nombre` | `TEXT` | `empleados.nombre` | Nombre del empleado |
| `empleado_activo` | `BOOLEAN` | `empleados.activo` | Si está activo (filtro recomendado) |
| `modalidad` | `TEXT` | `empleados.modalidad` | Modalidad laboral (sueldo/jornal/etc.) |
| `tipo_relacion` | `TEXT` | `empleados.tipo_relacion` | Tipo de relación laboral |
| `asignacion_principal` | `TEXT` | `empleados.asignacion_principal` | Área principal asignada |
| `asignacion_secundaria_1` | `TEXT` | `empleados.asignacion_secundaria_1` | Primera área secundaria (nullable) |
| `asignacion_secundaria_2` | `TEXT` | `empleados.asignacion_secundaria_2` | Segunda área secundaria (nullable) |
| `descanso_habitual` | `TEXT` | `empleados.descanso_habitual` | Día de descanso habitual |
| `descanso_alternativo` | `TEXT` | `empleados.descanso_alternativo` | Día de descanso alternativo (nullable) |
| `fecha` | `DATE` | `generate_series` | Fecha del día (dentro del rango) |
| `dia_semana` | `TEXT` | calculado | Nombre del día en español (lunes…domingo) |
| `tipo_turno` | `TEXT` | `turnos_personal.tipo_turno` | `maniana`, `tarde`, `mixto`, `partido`, `libre`, `no_asignado`; NULL si no hay registro |
| `estado` | `TEXT` | `turnos_personal.estado` | `normal`, `enfermo`, `capacitacion`, `vacaciones`, `falta`, `franco`, `compensado`; NULL si no hay registro |
| `observacion` | `TEXT` | `turnos_personal.observacion` | Observación libre (nullable) |
| `turno_realizado` | `BOOLEAN` | calculado | `TRUE` si estado no es ausencia/descanso |
| `horas_normales` | `INTEGER` | calculado | Horas estimadas según tipo_turno (maniana/tarde → 6, mixto/partido → 8, resto → 0) |
| `disponibilidad_turno` | `TEXT` | `empleado_disponibilidad.turno` | Disponibilidad declarada para ese día de semana (`maniana`, `tarde`, `mixto`, `no_disponible`); NULL si no configurado |
| `turno_fijo_tipo` | `TEXT` | `empleado_turno_fijo.tipo` | `partido` o `administrativo`; NULL si no tiene turno fijo |
| `es_feriado` | `BOOLEAN` | calculado | `TRUE` si la fecha está en `feriados` |
| `es_especial` | `BOOLEAN` | `feriados.es_especial` | `TRUE` si es feriado especial |
| `feriado_id` | `BIGINT` | `feriados.id` | ID del feriado (nullable) |
| `feriado_descripcion` | `TEXT` | `feriados.descripcion` | Descripción del feriado (nullable) |
| `feriado_especial_asignado` | `BOOLEAN` | `especial_rotacion` | `TRUE` si este empleado tiene asignado el feriado especial para este año |
| `feriado_trabajado_no_registrado` | `BOOLEAN` | calculado | `TRUE` si trabajó un feriado normal y no hay registro en `feriado_trabajado` |
| `feriado_especial_no_registrado` | `BOOLEAN` | calculado | `TRUE` si trabajó un feriado especial y no hay registro en `feriado_especial_trabajado` |
| `descanso_no_asignado` | `BOOLEAN` | calculado | `TRUE` si no trabajó y el estado no es una ausencia válida |
| `dia_trabajado_sin_turno` | `BOOLEAN` | calculado | `TRUE` si `turno_realizado = TRUE` y `tipo_turno IS NULL` |
| `persona_sin_asignacion` | `BOOLEAN` | calculado | `TRUE` si no existe ningún registro en `turnos_personal` para ese `(empleado_id, fecha)` |
| `sugerencia` | `TEXT` | calculado | Sugerencia operativa principal (ver sección 5); NULL si no hay alerta |

> **Nota:** `doble_turno_no_registrado` y `medio_turno_extra_no_registrado` se exponen como `FALSE` hasta que se agreguen las columnas `subturno`/`area` a `turnos_personal` (Etapa 4+). Se reservan como columnas para mantener el contrato estable.

| Columna | Tipo PostgreSQL | Valor hasta Etapa 4 |
|---|---|---|
| `doble_turno_no_registrado` | `BOOLEAN` | `FALSE` (placeholder) |
| `medio_turno_extra_no_registrado` | `BOOLEAN` | `FALSE` (placeholder) |
| `semana_desbalanceada` | `BOOLEAN` | `FALSE` (placeholder) |

---

## 3. Joins necesarios

```
public.empleados  (tabla base, todos los activos)
  │
  ├─── CROSS JOIN ─────────────────────── generate_series(desde, hasta) AS cal(fecha)
  │
  ├─── LEFT JOIN public.turnos_personal   ON (empleado_id, fecha)
  │
  ├─── LEFT JOIN public.feriados          ON (cal.fecha = feriados.fecha)
  │
  ├─── LEFT JOIN public.feriado_trabajado
  │         ON (empleado_id, feriado_id)
  │         — para detectar feriado_trabajado_no_registrado
  │
  ├─── LEFT JOIN public.feriado_especial_trabajado
  │         ON (empleado_id, feriado_id)
  │         — para detectar feriado_especial_no_registrado
  │
  ├─── LEFT JOIN public.empleado_disponibilidad
  │         ON (empleado_id, dia_semana)
  │         — dia_semana se convierte desde cal.fecha usando to_char(cal.fecha, 'ID') o similar
  │
  ├─── LEFT JOIN public.empleado_turno_fijo
  │         ON (empleado_id)
  │
  └─── LEFT JOIN public.especial_rotacion
            ON (empleado_id, feriado_id, EXTRACT(YEAR FROM cal.fecha))
            — para saber si este empleado tiene asignado el feriado especial
```

### Notas sobre `dia_semana`

La tabla `empleado_disponibilidad` guarda `dia_semana` como `TEXT` (p. ej. `'lunes'`, `'martes'`, etc.). El join se realiza convirtiendo la fecha del calendario a texto mediante:

```sql
to_char(cal.fecha, 'TMDay')  -- devuelve el nombre del día en el locale
```

o, si se usa un mapeo explícito:

```sql
CASE EXTRACT(ISODOW FROM cal.fecha)
  WHEN 1 THEN 'lunes'
  WHEN 2 THEN 'martes'
  WHEN 3 THEN 'miércoles'
  WHEN 4 THEN 'jueves'
  WHEN 5 THEN 'viernes'
  WHEN 6 THEN 'sábado'
  WHEN 7 THEN 'domingo'
END
```

El valor exacto dependerá de cómo se cargaron los datos en `empleado_disponibilidad`. Se debe alinear en la Etapa 3.

---

## 4. Alineación con `public.view_turnos_resumen_mensual_v3`

La lógica de validaciones de `fn_turnos_semana` se alinea directamente con la de `view_turnos_resumen_mensual_v3`:

| Flag | v3 (mensual) | fn_turnos_semana (semanal) |
|---|---|---|
| `turno_realizado` | ✅ mismo cálculo | ✅ mismo cálculo |
| `horas_normales` | ✅ mismo cálculo | ✅ mismo cálculo |
| `feriado_trabajado_no_registrado` | ✅ mismo cálculo | ✅ mismo cálculo |
| `feriado_especial_no_registrado` | ✅ mismo cálculo | ✅ mismo cálculo |
| `descanso_no_asignado` | ✅ mismo cálculo | ✅ mismo cálculo |
| `dia_trabajado_sin_turno` | ✅ mismo cálculo | ✅ mismo cálculo |
| `semana_desbalanceada` | `FALSE` placeholder | `FALSE` placeholder (Etapa 4) |
| `doble_turno_no_registrado` | `FALSE` placeholder | `FALSE` placeholder (Etapa 4) |
| `sugerencia` | ✅ mismo orden de prioridad | ✅ mismo orden de prioridad |

Diferencias respecto a v3:
- **v3** parte de `turnos_personal` y solo incluye empleados que ya tienen registros.
- **fn_turnos_semana** parte de `empleados` (activos) y hace `CROSS JOIN` con el calendario, de modo que aparece cada empleado incluso si no tiene turnos cargados (columna `persona_sin_asignacion = TRUE`).
- **fn_turnos_semana** añade columnas de `empleado_disponibilidad`, `empleado_turno_fijo` y `especial_rotacion` que v3 no incluye.

---

## 5. Lógica de sugerencias (prioridad heredada de v3)

```
PRIORIDAD 1 (crítico):
  semana_desbalanceada              → 'sugerir_descanso_obligatorio'
  feriado_trabajado_no_registrado   → 'registrar_feriado_trabajado'
  feriado_especial_no_registrado    → 'registrar_feriado_especial'
  dia_trabajado_sin_turno           → 'asignar_turno'
  persona_sin_asignacion            → 'asignar_turno'

PRIORIDAD 2 (operativo — disponible en Etapa 4 con area/subturno):
  mínimos por área no cubiertos     → 'cubrir_minimo_area'
  sobreasignación de área           → 'revisar_sobreasignacion'

PRIORIDAD 3 (disponibilidad):
  turno_realizado = FALSE
  AND estado NOT IN ('franco','descanso','vacaciones','enfermo','falta','compensado')
                                    → 'asignar_turno'

Sin alerta                          → NULL
```

---

## 6. Ejemplos de queries para consumo desde Flutter (via Supabase)

### 6.1 Semana actual

```sql
SELECT *
FROM public.fn_turnos_semana(
  date_trunc('week', current_date)::date,
  (date_trunc('week', current_date) + interval '6 days')::date
)
ORDER BY fecha, empleado_nombre;
```

### 6.2 Semana específica

```sql
SELECT *
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
ORDER BY fecha, empleado_nombre;
```

### 6.3 Solo empleados activos con alertas

```sql
SELECT empleado_id, empleado_nombre, fecha, tipo_turno, estado, sugerencia
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
WHERE sugerencia IS NOT NULL
  AND empleado_activo = TRUE
ORDER BY fecha, empleado_nombre;
```

### 6.4 Grilla semanal de un empleado

```sql
SELECT fecha, dia_semana, tipo_turno, estado, es_feriado, sugerencia
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
WHERE empleado_id = 42
ORDER BY fecha;
```

### 6.5 Desde Flutter (Dart) con `supabase_flutter`

```dart
// Consultar semana específica
final desde = '2026-04-06';
final hasta = '2026-04-12';

final response = await supabase
    .rpc('fn_turnos_semana', params: {'desde': desde, 'hasta': hasta});

// Con filtro de empleado
final response = await supabase
    .rpc('fn_turnos_semana', params: {'desde': desde, 'hasta': hasta})
    .eq('empleado_id', empleadoId);

// Solo alertas
final response = await supabase
    .rpc('fn_turnos_semana', params: {'desde': desde, 'hasta': hasta})
    .not('sugerencia', 'is', null);
```

> **Importante:** Supabase expone las funciones `RETURNS TABLE` como RPCs. El nombre del RPC en la API es el mismo que el de la función: `fn_turnos_semana`.

---

## 7. Notas y pendientes

### RLS (Row Level Security)
- **Hoy no hay RLS implementado en las migraciones de este repo.** Las políticas de seguridad a nivel fila están pendientes para una etapa futura.
- Cuando se implemente, la función deberá respetar la política: empleado solo ve sus propios turnos; admin/service_role ve todos.
- Esto puede lograrse con `SECURITY DEFINER` + filtro por `auth.uid()` dentro de la función, o con `SECURITY INVOKER` + policies sobre las tablas base.

### Tabla `feriado_trabajado` (bug conocido)
- La migración `20260404220000_create_feriado_trabajado.sql` contiene la definición duplicada de la tabla (dos bloques `CREATE TABLE IF NOT EXISTS`). No rompe por idempotencia, pero debe limpiarse en una migración de mantenimiento.

### Columnas `area` y `subturno`
- La tabla `turnos_personal` actualmente **no tiene** columnas `area` ni `subturno`. Los placeholders `doble_turno_no_registrado`, `medio_turno_extra_no_registrado` y `semana_desbalanceada` se mantienen como `FALSE` hasta que esas columnas se agreguen (Etapa 4+).

### Referencia a `view_turnos_resumen_mensual_v4`
- La v4 agrega cálculo de equivalencias de jornal sobre la v3. La `fn_turnos_semana` **no incluye** estos cálculos de liquidación; esa lógica es exclusiva del resumen mensual que alimenta al sistema madre.

---

## 8. Próximo paso

**Etapa 3 — Migración SQL:** Implementar `public.fn_turnos_semana(desde date, hasta date)` como función en una nueva migración Supabase, siguiendo el patrón de idempotencia del repo (`CREATE OR REPLACE FUNCTION`).
