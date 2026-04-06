# `public.fn_turnos_semana` — Función semanal parametrizada

> **Migración:** `20260406121957_create_fn_turnos_semana.sql`
> **Issue:** [#20](https://github.com/OscarDavids-Prog/turnos-personal/issues/20)
> **Etapa:** 3 — Migración SQL a Supabase
> **Fecha:** 2026-04-06

---

## Descripción

`public.fn_turnos_semana(p_desde date, p_hasta date)` devuelve una grilla de:

```
empleados activos × días del rango [p_desde, p_hasta]
```

Cada fila representa la situación de un empleado activo en un día específico: si tiene turno asignado, si ese día es feriado, qué disponibilidad declarada tiene para ese día de la semana, y si hay alguna alerta operativa que deba atenderse.

---

## Firma

```sql
public.fn_turnos_semana(
    p_desde date,   -- primer día del rango (inclusive)
    p_hasta date    -- último día del rango (inclusive)
)
RETURNS TABLE ( ... )
LANGUAGE sql STABLE
```

---

## Columnas retornadas

### Empleado

| Columna | Tipo | Descripción |
|---|---|---|
| `empleado_id` | `bigint` | ID del empleado (`public.empleados.id`) |
| `empleado_nombre` | `text` | Nombre del empleado |
| `empleado_activo` | `boolean` | Siempre `true` (la función filtra solo activos) |
| `modalidad` | `text` | `sueldo` o `jornal` |
| `tipo_relacion` | `text` | `mensual` o `jornal` |
| `asignacion_principal` | `text` | Área principal asignada (nullable) |
| `asignacion_secundaria_1` | `text` | Primera área secundaria (nullable) |
| `asignacion_secundaria_2` | `text` | Segunda área secundaria (nullable) |
| `descanso_habitual` | `text` | Día de descanso habitual (nullable) |
| `descanso_alternativo` | `text` | Día de descanso alternativo (nullable) |

### Calendario

| Columna | Tipo | Descripción |
|---|---|---|
| `fecha` | `date` | Fecha del día |
| `dow` | `int` | Día de la semana: 0=domingo … 6=sábado (`EXTRACT(DOW)`) |
| `dia_semana` | `text` | Nombre en español sin tilde: `lunes`, `martes`, `miercoles`, `jueves`, `viernes`, `sabado`, `domingo` |

### Turno

| Columna | Tipo | Descripción |
|---|---|---|
| `turno_id` | `bigint` | ID del registro en `turnos_personal` (NULL si no existe) |
| `tipo_turno` | `text` | `maniana`, `tarde`, `mixto`, `partido`, `libre`, `no_asignado`; NULL si no hay registro |
| `estado` | `text` | `normal`, `enfermo`, `capacitacion`, `vacaciones`, `falta`, `franco`, `compensado`; NULL si no hay registro |
| `observacion` | `text` | Texto libre (nullable) |
| `turno_realizado` | `boolean` | `true` si el estado indica trabajo real (no es ausencia ni descanso) |
| `horas_normales` | `integer` | Horas estimadas según tipo_turno (`maniana`/`tarde`→6, `mixto`/`partido`→8, resto→0) |

### Disponibilidad / turno fijo

| Columna | Tipo | Descripción |
|---|---|---|
| `disponibilidad_turno` | `text` | Turno declarado para ese día de la semana en `empleado_disponibilidad` (`maniana`, `tarde`, `mixto`, `no_disponible`); NULL si no configurado |
| `turno_fijo_tipo` | `text` | `partido` o `administrativo` desde `empleado_turno_fijo`; NULL si no aplica |

### Feriados

| Columna | Tipo | Descripción |
|---|---|---|
| `es_feriado` | `boolean` | `true` si la fecha aparece en `public.feriados` |
| `es_especial` | `boolean` | `true` si el feriado es especial (`feriados.es_especial`) |
| `feriado_id` | `bigint` | ID del feriado (NULL si no es feriado) |
| `feriado_descripcion` | `text` | Descripción del feriado (NULL si no es feriado) |
| `feriado_especial_asignado` | `boolean` | `true` si este empleado tiene asignado el feriado especial para el año correspondiente (vía `especial_rotacion`) |

### Validaciones operativas

| Columna | Tipo | Descripción |
|---|---|---|
| `persona_sin_asignacion` | `boolean` | `true` si no existe registro en `turnos_personal` para ese `(empleado_id, fecha)` |
| `feriado_trabajado_no_registrado` | `boolean` | `true` si trabajó un feriado normal y no hay registro en `feriado_trabajado` |
| `feriado_especial_no_registrado` | `boolean` | `true` si trabajó un feriado especial y no hay registro en `feriado_especial_trabajado` |
| `descanso_no_asignado` | `boolean` | `true` si hay registro con estado que no es ausencia válida pero no hubo trabajo real |
| `dia_trabajado_sin_turno` | `boolean` | `true` si `turno_realizado = true` pero `tipo_turno IS NULL` (guarda de consistencia) |
| `doble_turno_no_registrado` | `boolean` | Siempre `false` — placeholder hasta Etapa 4 (requiere columna `subturno`) |
| `medio_turno_extra_no_registrado` | `boolean` | Siempre `false` — placeholder hasta Etapa 4 (requiere columna `subturno`) |
| `semana_desbalanceada` | `boolean` | Siempre `false` — placeholder hasta Etapa 4 (lógica semanal compleja) |

### Sugerencia

| Columna | Tipo | Descripción |
|---|---|---|
| `sugerencia` | `text` | Sugerencia operativa principal; NULL si no hay alerta |

Valores posibles de `sugerencia` (en orden de prioridad):

| Valor | Condición que lo dispara |
|---|---|
| `'registrar_feriado_trabajado'` | `feriado_trabajado_no_registrado = true` |
| `'registrar_feriado_especial'` | `feriado_especial_no_registrado = true` |
| `'asignar_turno'` | `dia_trabajado_sin_turno = true`, o `persona_sin_asignacion = true`, o `descanso_no_asignado = true` |
| `NULL` | Sin alertas activas |

---

## Normalización de `dia_semana`

La tabla `public.empleado_disponibilidad` almacena `dia_semana` como `TEXT`. La función convierte la fecha usando `EXTRACT(ISODOW)` (independiente del locale de la BD) al siguiente mapa:

| ISODOW | Valor TEXT |
|---|---|
| 1 | `lunes` |
| 2 | `martes` |
| 3 | `miercoles` |
| 4 | `jueves` |
| 5 | `viernes` |
| 6 | `sabado` |
| 7 | `domingo` |

> **Importante:** Los datos insertados en `empleado_disponibilidad.dia_semana` **deben usar exactamente estos valores** (minúsculas, sin tilde) para que el join funcione correctamente.

---

## Joins internos

```
public.empleados (WHERE activo = true)
  │
  ├─ CROSS JOIN  generate_series(p_desde, p_hasta) AS cal(fecha)
  │
  ├─ LEFT JOIN   public.turnos_personal        ON (empleado_id, fecha)
  ├─ LEFT JOIN   public.empleado_disponibilidad ON (empleado_id, dia_semana::text)
  ├─ LEFT JOIN   public.empleado_turno_fijo     ON (empleado_id)
  ├─ LEFT JOIN   public.feriados                ON (fecha)
  ├─ LEFT JOIN   public.especial_rotacion       ON (empleado_id, feriado_id, anio)
  │
  │  (correlated subqueries en validaciones):
  ├─ NOT EXISTS  public.feriado_trabajado          ON (empleado_id, feriado_id)
  └─ NOT EXISTS  public.feriado_especial_trabajado ON (empleado_id, feriado_id)
```

---

## Cómo consumirla

### SQL directo (semana específica)

```sql
SELECT *
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
ORDER BY fecha, empleado_nombre;
```

### SQL — semana actual (lunes a domingo)

```sql
SELECT *
FROM public.fn_turnos_semana(
    date_trunc('week', current_date)::date,
    (date_trunc('week', current_date) + interval '6 days')::date
)
ORDER BY fecha, empleado_nombre;
```

### SQL — solo registros con alertas

```sql
SELECT empleado_id, empleado_nombre, fecha, tipo_turno, estado, sugerencia
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
WHERE sugerencia IS NOT NULL
ORDER BY fecha, empleado_nombre;
```

### SQL — grilla de un empleado puntual

```sql
SELECT fecha, dia_semana, tipo_turno, estado, es_feriado, sugerencia
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
WHERE empleado_id = 1
ORDER BY fecha;
```

### SQL — feriados trabajados sin registrar

```sql
SELECT empleado_id, empleado_nombre, fecha, feriado_descripcion, es_especial
FROM public.fn_turnos_semana('2026-04-06', '2026-04-12')
WHERE feriado_trabajado_no_registrado = true
   OR feriado_especial_no_registrado  = true;
```

### Desde Flutter / Dart (Supabase RPC)

```dart
// Semana específica
final response = await supabase
    .rpc('fn_turnos_semana', params: {
      'p_desde': '2026-04-06',
      'p_hasta': '2026-04-12',
    });

// Con filtro de empleado
final response = await supabase
    .rpc('fn_turnos_semana', params: {
      'p_desde': '2026-04-06',
      'p_hasta': '2026-04-12',
    })
    .eq('empleado_id', empleadoId);

// Solo alertas
final response = await supabase
    .rpc('fn_turnos_semana', params: {
      'p_desde': '2026-04-06',
      'p_hasta': '2026-04-12',
    })
    .not('sugerencia', 'is', null);
```

> **Nota:** Supabase expone las funciones `RETURNS TABLE` como RPCs. El nombre del parámetro en la API coincide con el nombre de la función: `fn_turnos_semana`.

---

## Ejemplo de output esperado

Para una BD con 2 empleados activos y el rango `2026-04-06` a `2026-04-07`:

| empleado_id | empleado_nombre | fecha | tipo_turno | estado | es_feriado | persona_sin_asignacion | sugerencia |
|---|---|---|---|---|---|---|---|
| 1 | Ana García | 2026-04-06 | maniana | normal | false | false | null |
| 1 | Ana García | 2026-04-07 | null | null | false | true | asignar_turno |
| 2 | Carlos López | 2026-04-06 | null | null | false | true | asignar_turno |
| 2 | Carlos López | 2026-04-07 | tarde | normal | false | false | null |

---

## Notas

- **RLS:** No se implementa RLS en esta etapa. La función usa `SECURITY INVOKER` (valor por defecto). Cuando se implemente RLS, se deberá agregar filtro por `auth.uid()` o cambiar a `SECURITY DEFINER`.
- **Idempotencia:** `CREATE OR REPLACE FUNCTION` es segura de re-ejecutar sin efectos laterales.
- **Placeholders:** `doble_turno_no_registrado`, `medio_turno_extra_no_registrado` y `semana_desbalanceada` devuelven siempre `false` hasta que se agreguen las columnas `subturno`/`area` a `turnos_personal` (Etapa 4+).
- **Bug conocido:** La migración `20260404220000_create_feriado_trabajado.sql` contiene la definición de la tabla duplicada. No afecta esta función (idempotente por `IF NOT EXISTS`), pero debe limpiarse en una migración de mantenimiento posterior.
