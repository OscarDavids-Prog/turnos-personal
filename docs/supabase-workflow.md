# Supabase Workflow

Flujo de trabajo estándar para trabajar con Supabase en el módulo **turnos-personal**.

## Herramientas requeridas

- Supabase CLI ≥ 1.170: `npm install -g supabase`
- Variables de entorno en `.env` (no commitear):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

## Ambiente local

### Iniciar entorno local

```bash
supabase start
```

Esto levanta PostgreSQL, Studio y Auth localmente usando Docker.

### Aplicar migraciones localmente

```bash
supabase db reset
```

`db reset` elimina y recrea la base de datos local aplicando todas las migraciones en orden. Como todas las migraciones son idempotentes, también se puede usar:

```bash
supabase db push --local
```

### Inspeccionar la base local

```bash
supabase db diff
```

Muestra diferencias entre el esquema local y las migraciones.

## Crear una nueva migración

```bash
# Desde la raíz del repositorio
supabase migration new <nombre_descriptivo>
```

Esto crea el archivo `supabase/migrations/<timestamp>_<nombre_descriptivo>.sql`.  
Editar el archivo siguiendo `docs/MIGRATION_GUIDELINES.md`.

## Aplicar migraciones en producción

```bash
supabase db push
```

> **Nota:** Siempre hacer `supabase db push` desde una rama aprobada y mergeada a `main`. Nunca desde ramas de feature.

## Revertir una migración

Supabase CLI no soporta rollback automático. Para revertir:

1. Crear una nueva migración de tipo `drop` o `alter` que deshaga el cambio.
2. Seguir el mismo proceso de revisión y aprobación.

## Row Level Security (RLS)

Toda tabla nueva debe tener RLS habilitado. Verificar con:

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

## Roles disponibles

| Rol | Descripción |
|-----|-------------|
| `anon` | Usuarios no autenticados (acceso mínimo o nulo) |
| `authenticated` | Empleados autenticados via Supabase Auth |
| `admin` | Administradores (identificados por claim en JWT) |
| `service_role` | Backend / funciones serverless |

## Verificar políticas RLS

```sql
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```
