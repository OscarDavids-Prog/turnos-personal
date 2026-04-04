# Arquitectura del sistema

Descripción técnica de la arquitectura del módulo **turnos-personal**.

## Visión general

```
┌─────────────────────────────────────────────────────┐
│                   Supabase                          │
│  ┌───────────────┐  ┌─────────┐  ┌───────────────┐ │
│  │  PostgreSQL   │  │   Auth  │  │   Storage     │ │
│  │  (tablas +    │  │  (JWT)  │  │  (futuro)     │ │
│  │   RLS + RBAC) │  └─────────┘  └───────────────┘ │
│  └───────────────┘                                  │
└──────────────────────┬──────────────────────────────┘
                       │ REST / Realtime
          ┌────────────┴────────────┐
          │                         │
┌─────────▼──────────┐   ┌─────────▼──────────┐
│    app/admin        │   │   app/empleados     │
│  Flutter (interno)  │   │  Flutter (APK)      │
│                     │   │                     │
│  Screens            │   │  Screens            │
│  └ Tablero semanal  │   │  └ Semana           │
│  └ Editor turno     │   │  └ Mes              │
│  └ Resumen mensual  │   │  └ Notificaciones   │
│  └ Feriados         │   │                     │
│                     │   │  Services           │
│  Providers          │   │  └ TurnosService    │
│  └ TurnosProvider   │   │                     │
│  └ FeriadosProvider │   │  Models             │
│  └ EmpleadosProvider│   │  └ Turno            │
│                     │   │  └ Empleado         │
│  Services           │   └─────────────────────┘
│  └ SupabaseService  │
│  └ TurnosService    │
│  └ FeriadosService  │
│                     │
│  Models             │
│  └ Turno            │
│  └ Empleado         │
│  └ Feriado          │
└─────────────────────┘
```

## Capas de la aplicación Flutter

### 1. Models (`lib/models/`)

Clases Dart que representan las entidades de la base de datos.  
Cada modelo implementa `fromJson(Map<String, dynamic>)` y `toJson()`.  
Los modelos son inmutables (campos `final`).

### 2. Services (`lib/services/`)

Clases que interactúan directamente con Supabase.  
- `SupabaseService`: inicialización y acceso al cliente.
- `TurnosService`: CRUD de turnos con validaciones de negocio.
- `FeriadosService`: CRUD de feriados y registro de trabajados.
- `EmpleadosService`: lectura de empleados y extensiones.

### 3. Providers (`lib/providers/`) – solo app admin

State management con `provider` (o `riverpod`).  
Los providers consumen los servicios y exponen el estado a los widgets.

### 4. Screens (`lib/screens/`)

Widgets de pantalla completa. Consumen providers (admin) o servicios directamente (empleados).  
No contienen lógica de negocio.

## Decisiones de diseño

| Decisión | Justificación |
|----------|---------------|
| Supabase como backend | Integración con sistema madre existente; RLS nativo |
| Flutter para ambas apps | Única codebase para Android/iOS; APK para empleados |
| Migraciones idempotentes | Permite `db push` y `db reset` sin riesgo |
| Sin modificar tablas existentes | Evita romper el sistema madre |
| RLS en todas las tablas nuevas | Seguridad por defecto |
| `provider` para estado | Madurez y simplicidad para el equipo |

## Flujo de autenticación

1. El usuario abre la app e ingresa email + contraseña.
2. Supabase Auth devuelve un JWT con los claims del usuario.
3. El claim `role` en el JWT determina los permisos (RLS lo hace cumplir en DB).
4. El token se renueva automáticamente con el refresh token.

## Escalabilidad futura

- **Notificaciones push:** agregar `supabase_functions` + Firebase Cloud Messaging.
- **Auditoría:** activar triggers sobre tablas operativas según `AUDITORIA_STANDARD.md`.
- **Reportes PDF:** agregar `pdf` package en Flutter.
- **Modo offline:** agregar `hive` o `drift` como caché local.
