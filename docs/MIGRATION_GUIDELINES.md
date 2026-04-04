# Migration Guidelines

Convenciones para la creación y mantenimiento de migraciones de base de datos en el módulo **turnos-personal**.

## Nombre del archivo

Formato obligatorio:

```
YYYYMMDDHHMMSS_<verbo>_<objeto>.sql
```

Ejemplos válidos:

```
20260404120000_add_columns_empleados.sql
20260404120001_create_feriados.sql
20260404120002_alter_turnos_personal_add_estado.sql
20260404120003_drop_old_view_turnos.sql
```

### Verbos permitidos

| Verbo | Uso |
|-------|-----|
| `create` | Crear una tabla, función, índice o vista nueva |
| `add` | Agregar columnas a una tabla existente |
| `alter` | Modificar el tipo o restricción de una columna existente |
| `drop` | Eliminar un objeto de la base de datos |
| `seed` | Insertar datos de referencia |

## Idempotencia

Toda migración **debe** poder ejecutarse más de una vez sin error ni efecto secundario.

### Tablas

```sql
CREATE TABLE IF NOT EXISTS nombre_tabla ( ... );
```

### Columnas

```sql
ALTER TABLE nombre_tabla
  ADD COLUMN IF NOT EXISTS nueva_columna tipo;
```

### Índices

```sql
CREATE INDEX IF NOT EXISTS idx_nombre ON tabla(columna);
```

### Datos de referencia

```sql
INSERT INTO tabla (col1, col2)
VALUES ('val1', 'val2')
ON CONFLICT (col_unica) DO NOTHING;
```

### Funciones y triggers

```sql
CREATE OR REPLACE FUNCTION nombre_funcion() ...
```

## Reglas adicionales

1. **No modificar migraciones ya aplicadas.** Corregir errores mediante una nueva migración.
2. **Una migración = un propósito.** No mezclar creación de tablas con inserción de datos de otra entidad.
3. **No tocar tablas del sistema madre.** Solo extender con `ADD COLUMN IF NOT EXISTS` cuando sea estrictamente necesario y esté aprobado.
4. **Habilitar RLS** en toda tabla nueva:
   ```sql
   ALTER TABLE nueva_tabla ENABLE ROW LEVEL SECURITY;
   ```
5. **Definir al menos una política RLS** antes de que la tabla sea usada en producción.
6. **Comentar el propósito** de cada tabla y columna no obvia con `COMMENT ON`.

## Flujo de trabajo

```
1. Crear archivo de migración con timestamp del momento de creación.
2. Escribir SQL idempotente.
3. Probar localmente con: supabase db reset (ambiente local).
4. Incluir la migración en el PR con el checklist de DOCUMENTACION_POR_PR.md.
5. Aplicar en producción con: supabase db push.
```
