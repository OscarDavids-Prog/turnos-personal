# turnos-personal

Sistema modular para la gestión de turnos rotativos del personal de **Lavasol**.

## Descripción

Este módulo se integra a la base de datos existente del sistema madre sin modificar tablas ni triggers existentes. Proporciona:

- **App interna (Flutter):** tablero semanal tipo Excel, editor de turnos con validaciones, cálculo mensual y gestión de feriados/compensados.
- **APK empleados (Flutter):** visualización de turnos semanales, actividad mensual y notificaciones opcionales.
- **Backend (Supabase):** tablas nuevas con RLS, RBAC, migraciones idempotentes y auditoría futura.

## Estructura del repositorio

```
turnos-personal/
├── apps/
│   ├── admin/          # Flutter – app interna de administración
│   └── empleados/      # Flutter – APK para empleados
├── supabase/
│   └── migrations/     # Migraciones SQL idempotentes
└── docs/
    ├── user/           # Guías de usuario
    ├── dev/            # Documentación técnica
    ├── releases/       # Historial de versiones
    ├── supabase-workflow.md
    ├── MIGRATION_GUIDELINES.md
    ├── AUDITORIA_STANDARD.md
    └── DOCUMENTACION_POR_PR.md
```

## Inicio rápido

### Requisitos

- Flutter ≥ 3.19
- Dart ≥ 3.3
- Supabase CLI ≥ 1.170
- Cuenta Supabase con acceso al proyecto de Lavasol

### Configuración

```bash
# Clonar el repositorio
git clone https://github.com/OscarDavids-Prog/turnos-personal.git
cd turnos-personal

# Aplicar migraciones en Supabase
supabase db push

# App admin
cd apps/admin
flutter pub get
flutter run

# APK empleados
cd apps/empleados
flutter pub get
flutter run
```

## Documentación

Consultar [`docs/index.md`](docs/index.md) para el índice completo de documentación.

## Contribución

Ver [`docs/DOCUMENTACION_POR_PR.md`](docs/DOCUMENTACION_POR_PR.md) para los estándares de contribución y documentación por PR.

## Licencia

Uso interno – Lavasol.
