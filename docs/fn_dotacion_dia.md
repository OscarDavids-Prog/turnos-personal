# `public.fn_dotacion_dia` — Función diaria de dotación por área y bloque

> **Migración:** `20260406150000_create_fn_dotacion_dia.sql`
> **Fecha:** 2026-04-06

---

## Descripción

`public.fn_dotacion_dia(p_fecha date)` devuelve el estado de dotación para **todas las áreas activas** en ambos bloques (mañana/tarde) para un día dado.

Está diseñada para alimentar la **pantalla diaria de dotación**: muestra cuánta cobertura real hay, cuánto pide la configuración mínima/máxima, si faltan o sobran personas, y qué empleados aportan a cada área/bloque ese día.

No tiene efectos secundarios (solo lectura).

---

## Firma

```sql
public.fn_dotacion_dia(p_fecha date)
RETURNS TABLE ( ... )
LANGUAGE sql STABLE
```

---

## Columnas retornadas

| Columna | Tipo | Descripción |
|---|---|---|
| `fecha` | `date` | Fecha consultada (`p_fecha`) |
| `dia` | `int` | Día ISO de la semana: 1=lunes … 7=domingo |
| `area_id` | `bigint` | ID del área (`public.areas_turnos.id`) |
| `area_codigo` | `text` | Código del área (ej. `'plancha'`) |
| `area_nombre` | `text` | Nombre del área (ej. `'Plancha'`) |
| `bloque` | `text` | `'maniana'` o `'tarde'` |
| `cobertura` | `numeric` | Sumatoria de aportes reales de empleados activos en ese bloque |
| `min_recomendado` | `int` | Mínimo configurado (default `0` si no hay config) |
| `max_recomendado` | `int` | Máximo configurado (default `999` si no hay config) |
| `min_intermedios` | `int` | Mínimo de turnos intermedios (default `0`) |
| `max_intermedios` | `int` | Máximo de turnos intermedios (default `999`) |
| `faltan` | `numeric` | `greatest(min_recomendado − cobertura, 0)` |
| `sobran` | `numeric` | `greatest(cobertura − max_recomendado, 0)` |
| `empleados` | `jsonb` | Array JSON de empleados que aportan a ese bloque (ver estructura abajo) |

### Estructura del array `empleados`

```json
[
  {
    "id":            123,
    "nombre":        "Nombre del empleado",
    "tipo_turno":    "maniana",
    "aporte_maniana": 1.0,
    "aporte_tarde":   0.0,
    "es_descanso":   false
  }
]
```

- `es_descanso`: `true` si `p_fecha` coincide con el `descanso_habitual_dia` o el `descanso_alternativo_dia` del empleado.
- El array es `[]` (vacío) si ningún empleado activo aporta a ese bloque ese día.

---

## Comportamiento

| Caso | Resultado |
|---|---|
| Área activa sin turnos cargados | `cobertura = 0`, `empleados = []` |
| Área sin config en `dotacion_area_bloque_config` | `min = 0`, `max = 999`, `faltan = 0`, `sobran = 0` |
| Empleado con `tipo_turno = 'libre'` | `aporte_* = 0`, no aparece en lista de empleados |
| Empleado con `asignacion_principal_area_id = NULL` | Ignorado |
| Área con `activa = false` | No aparece en el resultado |

---

## Tablas utilizadas

| Tabla | Uso |
|---|---|
| `public.areas_turnos` | Catálogo de áreas (base del resultado) |
| `public.empleados` | Empleados activos y su área principal |
| `public.turnos_personal` | Turno del día por empleado |
| `public.equivalencia_turno_bloque` | Aportes por tipo de turno |
| `public.dotacion_area_bloque_config` | Mínimos/máximos por área, día y bloque |

---

## Ejemplo de uso

```sql
-- Dotación del martes 2026-04-07
SELECT * FROM public.fn_dotacion_dia('2026-04-07')
ORDER BY area_codigo, bloque;

-- Solo áreas con bache (faltan > 0)
SELECT area_codigo, bloque, cobertura, min_recomendado, faltan
FROM public.fn_dotacion_dia('2026-04-07')
WHERE faltan > 0
ORDER BY faltan DESC;

-- Empleados de plancha por la mañana
SELECT empleado->>'nombre' AS nombre,
       empleado->>'tipo_turno' AS tipo_turno
FROM public.fn_dotacion_dia('2026-04-07'),
     jsonb_array_elements(empleados) AS empleado
WHERE area_codigo = 'plancha'
  AND bloque      = 'maniana';
```

---

## Ordenamiento de la salida

Las filas se devuelven ordenadas por:
1. `areas_turnos.orden` (NULLS LAST)
2. `areas_turnos.codigo` alfabético
3. `bloque` (`'maniana'` antes que `'tarde'` por orden ASCII)
