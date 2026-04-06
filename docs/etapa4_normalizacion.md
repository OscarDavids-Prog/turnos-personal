# Etapa 4 — Normalización: Áreas, Días, Dotación y Equivalencias

> **Issue:** [#20](https://github.com/OscarDavids-Prog/turnos-personal/issues/20)
> **Etapa:** 4 — Normalización + Matrices de dotación + equivalencias
> **Fecha:** 2026-04-06

---

## Nota operativa: sistema vivo

> ⚠️ **El sistema es vivo.** Las validaciones de dotación y asignación **advierten y sugieren**, pero **nunca bloquean** la operación. El operador siempre puede registrar o modificar un turno independientemente de las advertencias de cobertura.

---

## 1. Catálogo de días de la semana (`public.dias_semana`)

Tabla de referencia fija. La UI muestra el `nombre`, los cálculos usan el `id`.

| id | nombre    |
|----|-----------|
| 1  | lunes     |
| 2  | martes    |
| 3  | miercoles |
| 4  | jueves    |
| 5  | viernes   |
| 6  | sabado    |
| 7  | domingo   |

**Cómo se usa en la UI:**
- En el formulario de empleado, los selects de `descanso_habitual_dia` y `descanso_alternativo_dia` listan estos nombres.
- La BD almacena solo el `id` (FK a esta tabla).
- En cualquier vista o informe, se hace JOIN a `dias_semana` para mostrar el nombre legible.

---

## 2. Catálogo de áreas (`public.areas_turnos`)

Catálogo de las áreas operativas de la lavandería.

| codigo        | nombre        | orden |
|---------------|---------------|-------|
| lavadero      | Lavadero      | 1     |
| plancha       | Plancha       | 2     |
| pr_persona    | PR Persona    | 3     |
| pr_delantales | PR Delantales | 4     |
| toallas       | Toallas       | 5     |
| desmanche     | Desmanche     | 6     |
| reparto       | Reparto       | 7     |
| mostrador     | Mostrador     | 8     |
| mantenimiento | Mantenimiento | 9     |

**Cómo se usa en la UI (pantalla por empleado):**
- El formulario de empleado tiene tres selects de área (principal, secundaria 1, secundaria 2).
- Cada select lista `areas_turnos` filtrado por `activa = true`, ordenado por `orden`.
- La BD almacena `asignacion_principal_area_id`, `asignacion_secundaria_1_area_id`, `asignacion_secundaria_2_area_id` como FK.
- Reglas UX:
  - Área principal es obligatoria (NOT NULL).
  - Las secundarias son opcionales (NULL si el empleado no es polivalente).
  - No se permite seleccionar la misma área en principal y secundaria (constraints en BD + validación de UI).
  - Secundaria 1 y secundaria 2 tampoco pueden ser iguales.

---

## 3. Asignaciones y descansos en `public.empleados`

Tras la migración de Etapa 4, la tabla `empleados` incorpora columnas FK y elimina las columnas TEXT legacy:

| Columna nueva                     | Tipo      | Descripción |
|-----------------------------------|-----------|-------------|
| `asignacion_principal_area_id`    | bigint NN | Área principal obligatoria |
| `asignacion_secundaria_1_area_id` | bigint    | Primera área polivalente (NULL si no aplica) |
| `asignacion_secundaria_2_area_id` | bigint    | Segunda área polivalente (NULL si no aplica) |
| `descanso_habitual_dia`           | smallint  | Día habitual de descanso, 1..7 (NULL para empleados no fijos) |
| `descanso_alternativo_dia`        | smallint  | Día alternativo de descanso, 1..7 (NULL si no tiene) |

Columnas eliminadas (legacy TEXT): `asignacion_principal`, `asignacion_secundaria_1`, `asignacion_secundaria_2`, `descanso_habitual`, `descanso_alternativo`.

### Constraints de consistencia

| Constraint | Regla |
|---|---|
| `chk_empleados_sec1_ne_principal` | secundaria_1 ≠ principal cuando no es NULL |
| `chk_empleados_sec2_ne_principal` | secundaria_2 ≠ principal cuando no es NULL |
| `chk_empleados_sec2_ne_sec1` | secundaria_2 ≠ secundaria_1 cuando ambas no son NULL |
| `chk_empleados_descanso_alt_ne_hab` | alternativo ≠ habitual cuando alternativo no es NULL |

---

## 4. Matriz de dotación (`public.dotacion_area_bloque_config`)

Permite configurar, por cada **área × día × bloque**, los valores mínimos y máximos de dotación recomendada.

| Columna | Descripción |
|---|---|
| `area_id` | FK a `areas_turnos` |
| `dia` | Día de la semana (1..7, FK a `dias_semana`) |
| `bloque` | `'maniana'` o `'tarde'` |
| `min_recomendado` | Mínimo de empleados recomendados en ese bloque |
| `max_recomendado` | Máximo de empleados recomendados en ese bloque |
| `min_intermedios` | Mínimo de empleados con turno mixto/intermedio esperados |
| `max_intermedios` | Máximo de empleados con turno mixto/intermedio aceptados |

**Combinación única:** `(area_id, dia, bloque)`.

**Cómo se usa:**
- La pantalla de **día completo** calcula la cobertura real de cada celda `área × bloque` usando las equivalencias (ver sección 5).
- Si `cobertura_real < min_recomendado` → semáforo rojo / advertencia "faltan N".
- Si `cobertura_real > max_recomendado` → advertencia "sobran N".
- Las advertencias son **no bloqueantes** (el sistema es vivo).

---

## 5. Equivalencias de cobertura (`public.equivalencia_turno_bloque`)

Define cuánto aporta cada tipo de turno a cada bloque del día.

| tipo_turno   | aporte_maniana | aporte_tarde | jornal_total | Nota |
|-------------|---------------|-------------|-------------|------|
| `maniana`    | 1.0           | 0.0         | 1.0         | Jornada completa, cubre bloque mañana |
| `tarde`      | 0.0           | 1.0         | 1.0         | Jornada completa, cubre bloque tarde |
| `mixto`      | 0.5           | 0.5         | 1.0         | **Alias operativo: mixto == intermedio** |
| `partido`    | 0.5           | 0.5         | 1.0         | Solo aplica en **mostrador** |
| `libre`      | 0.0           | 0.0         | 0.0         | No cubre dotación |
| `no_asignado`| 0.0           | 0.0         | 0.0         | Sin asignación, no cubre dotación |

### Notas clave

- **`mixto` == `intermedio`:** Son el mismo concepto. En la BD se guarda `mixto` (valor existente del check); en la UI y en los docs se puede mostrar como "Intermedio". La tabla de equivalencias lo documenta formalmente.
- **`partido` (mostrador):** El turno partido se aplica exclusivamente en el área Mostrador. Un empleado con turno `partido` ese día cubre 0.5 de la dotación de mañana **y** 0.5 de tarde, completando 1 jornal diario. La UI puede filtrar o advertir si `partido` se usa en un área distinta a Mostrador.

---

## 6. Vista de día completo (pantalla operativa)

Para asegurar distribución correcta y detectar baches:

```
┌─────────────────────────────────────────────────────┐
│  Día: lunes 2026-04-06   ◄ ►                       │
├──────────────┬──────────────────┬────────────────────┤
│ Área         │ Bloque Mañana    │ Bloque Tarde       │
│              │ real/min/max     │ real/min/max       │
├──────────────┼──────────────────┼────────────────────┤
│ Lavadero     │ 3/2/5 ✅        │ 2/2/4 ✅           │
│ Plancha      │ 1/2/3 🔴 falta 1│ 2/2/3 ✅           │
│ Mostrador    │ 1/1/2 ✅        │ 1/1/2 ✅           │
│ ...          │ ...              │ ...                │
└──────────────┴──────────────────┴────────────────────┘
```

La cobertura real se calcula sumando `aporte_maniana` / `aporte_tarde` de cada empleado activo ese día, usando su `asignacion_principal_area_id` como área.

---

## 7. Cálculo de cobertura (pseudocódigo SQL)

```sql
SELECT
    e.asignacion_principal_area_id AS area_id,
    SUM(eq.aporte_maniana) AS cobertura_maniana,
    SUM(eq.aporte_tarde)   AS cobertura_tarde
FROM public.turnos_personal tp
JOIN public.empleados e ON e.id = tp.empleado_id
JOIN public.equivalencia_turno_bloque eq ON eq.tipo_turno = tp.tipo_turno
WHERE tp.fecha = :fecha
  AND e.activo = true
GROUP BY e.asignacion_principal_area_id;
```

Luego se hace JOIN a `dotacion_area_bloque_config` para comparar con min/max y generar los semáforos.
