# Modelos de datos

Descripción del esquema de base de datos del módulo **turnos-personal**.

## Extensión de la tabla `empleados`

> Las siguientes columnas se agregan a la tabla `empleados` existente **sin modificar columnas ni restricciones ya existentes**.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `fecha_nacimiento` | `DATE` | Fecha de nacimiento del empleado |
| `direccion` | `TEXT` | Dirección postal |
| `fecha_ingreso` | `DATE` | Fecha de ingreso a Lavasol |
| `categoria` | `TEXT` | Categoría laboral |
| `asignacion_principal` | `TEXT` | Sección principal (Lavadero, Plancha, etc.) |
| `asignacion_secundaria_1` | `TEXT` | Primera asignación secundaria opcional |
| `asignacion_secundaria_2` | `TEXT` | Segunda asignación secundaria opcional |
| `descanso_habitual` | `TEXT` | Día de descanso habitual (ej: `"domingo"`) |
| `descanso_alternativo` | `TEXT` | Día de descanso alternativo opcional |

---

## Tabla `turnos_personal`

Registro diario de turnos por empleado.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | `BIGINT` (PK) | Generado automáticamente |
| `empleado_id` | `UUID` | FK → `empleados.id` |
| `fecha` | `DATE` | Fecha del turno |
| `tipo_turno` | `TEXT` | `manana`, `tarde`, `intermedio`, `descanso` |
| `estado` | `TEXT` | `NULL`, `ENF`, `CAP`, `VAC`, `X` |
| `compensado` | `BOOLEAN` | Si el día fue compensado (feriado) |
| `creado_en` | `TIMESTAMPTZ` | Fecha/hora de creación |
| `actualizado_en` | `TIMESTAMPTZ` | Fecha/hora de última actualización |

**Restricciones:**
- `(empleado_id, fecha)` UNIQUE — un turno por empleado por día.
- `tipo_turno` IN (`manana`, `tarde`, `intermedio`, `descanso`).
- `estado` IN (`ENF`, `CAP`, `VAC`, `X`) o NULL.

---

## Tabla `feriados`

Catálogo de feriados.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | `INT` (PK) | Generado automáticamente |
| `fecha` | `DATE` | Fecha del feriado (UNIQUE) |
| `nombre` | `TEXT` | Nombre descriptivo |
| `tipo` | `TEXT` | `nacional`, `provincial`, `comercio`, `especial` |
| `es_especial` | `BOOLEAN` | TRUE para 1/1, 1/5, 25/12 |

---

## Tabla `feriado_trabajado`

Registro de feriados normales trabajados.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | `BIGINT` (PK) | Generado automáticamente |
| `empleado_id` | `UUID` | FK → `empleados.id` |
| `feriado_id` | `INT` | FK → `feriados.id` |
| `modalidad` | `TEXT` | `compensado` o `cobrado` |
| `creado_en` | `TIMESTAMPTZ` | Fecha/hora de creación |

**Restricciones:**
- `(empleado_id, feriado_id)` UNIQUE.
- `modalidad` IN (`compensado`, `cobrado`).

---

## Tabla `feriado_especial_trabajado`

Registro de feriados especiales trabajados (1/1, 1/5, 25/12).

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | `BIGINT` (PK) | Generado automáticamente |
| `empleado_id` | `UUID` | FK → `empleados.id` |
| `feriado_id` | `INT` | FK → `feriados.id` (es_especial = TRUE) |
| `tipo_turno` | `TEXT` | Turno único del día especial |
| `creado_en` | `TIMESTAMPTZ` | Fecha/hora de creación |

**Restricciones:**
- `(empleado_id, feriado_id)` UNIQUE.

---

## Tabla `especial_rotacion`

Rotación anual del personal para los 3 días especiales.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | `INT` (PK) | Generado automáticamente |
| `anio` | `INT` | Año de la rotación |
| `feriado_id` | `INT` | FK → `feriados.id` (es_especial = TRUE) |
| `empleado_id` | `UUID` | FK → `empleados.id` |
| `orden` | `INT` | Posición en la rotación |

**Restricciones:**
- `(anio, feriado_id, empleado_id)` UNIQUE.

---

## Diagrama de relaciones simplificado

```
empleados (existente, extendida)
    │
    ├─── turnos_personal (N)
    ├─── feriado_trabajado (N) ──── feriados (1)
    ├─── feriado_especial_trabajado (N) ── feriados (1, es_especial=TRUE)
    └─── especial_rotacion (N) ──── feriados (1, es_especial=TRUE)
```
