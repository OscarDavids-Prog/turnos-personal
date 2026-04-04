# Estándar de Auditoría

Definición del estándar de auditoría para el módulo **turnos-personal**. Las tablas de auditoría aún no se implementan en esta versión, pero este documento establece la arquitectura esperada para que cualquier implementación futura sea consistente.

## Principios

1. **Inmutabilidad:** los registros de auditoría nunca se modifican ni eliminan.
2. **Completitud:** se registra quién hizo qué, sobre qué objeto y cuándo.
3. **Independencia:** las tablas de auditoría son separadas de las operativas.
4. **Bajo acoplamiento:** la auditoría se implementa via triggers de base de datos, no en la capa de aplicación.

## Estructura esperada de la tabla de auditoría

```sql
CREATE TABLE IF NOT EXISTS audit_log (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tabla        TEXT        NOT NULL,  -- nombre de la tabla auditada
  operacion    TEXT        NOT NULL,  -- INSERT | UPDATE | DELETE
  registro_id  TEXT        NOT NULL,  -- id del registro afectado (cast a text)
  datos_antes  JSONB,                 -- fila antes del cambio (NULL en INSERT)
  datos_despues JSONB,                -- fila después del cambio (NULL en DELETE)
  usuario_id   UUID,                  -- auth.uid() del usuario que realizó el cambio
  ejecutado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Solo el rol service_role puede leer auditoría
CREATE POLICY "solo service_role lee audit_log"
  ON audit_log FOR SELECT
  USING (auth.role() = 'service_role');
```

## Trigger genérico (referencia futura)

```sql
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO audit_log (tabla, operacion, registro_id, datos_antes, datos_despues, usuario_id)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    CASE TG_OP WHEN 'DELETE' THEN OLD.id::TEXT ELSE NEW.id::TEXT END,
    CASE TG_OP WHEN 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
    CASE TG_OP WHEN 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
    auth.uid()
  );
  RETURN NULL;
END;
$$;
```

## Tablas que deberán auditarse (fase futura)

| Tabla | Operaciones |
|-------|-------------|
| `turnos_personal` | INSERT, UPDATE, DELETE |
| `feriado_trabajado` | INSERT, UPDATE, DELETE |
| `feriado_especial_trabajado` | INSERT, UPDATE, DELETE |
| `especial_rotacion` | INSERT, UPDATE |

## Consideraciones de privacidad

- Los datos de auditoría pueden contener información laboral sensible.
- El acceso debe restringirse al rol `admin` y `service_role`.
- No exponer `audit_log` en las APIs públicas de la app de empleados.
