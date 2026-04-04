# Turnos Personal — Sistema Lavasol

Módulo independiente para la gestión de turnos rotativos del personal.  
Este proyecto se integra a la base de datos del sistema madre, pero mantiene código, documentación y estructura completamente separada.

## Objetivos del módulo
- Administrar turnos semanales con validaciones operativas.
- Registrar feriados, feriados especiales y compensados.
- Calcular actividad mensual por empleado.
- Proveer una app interna (Flutter) para administración.
- Proveer una APK para empleados (consulta de turnos y actividad).

## Tecnologías
- Flutter (app interna + APK empleados)
- Supabase (migraciones, RLS, RBAC)
- GitHub (versionado, documentación por PR)

## Estructura inicial del repositorio
turnos-personal/
│
├── docs/                 # Documentación (usuario + técnica)
├── supabase/             # Migraciones y estructura de BD
│   └── migrations/
└── flutter/              # Proyecto Flutter (se creará más adelante)

## Estándares heredados del sistema madre
- Migraciones idempotentes (ver MIGRATION_GUIDELINES.md)
- Documentación obligatoria por PR (ver DOCUMENTACION_POR_PR.md)
- Auditoría modular (AUDITORIA_STANDARD.md)
- Convención de releases por fecha (YYYY-MM-DD)

## Roadmap inicial
1. Crear estructura base del repo  
2. Agregar columnas nuevas a empleados  
3. Crear tablas del módulo de turnos  
4. Crear proyecto Flutter  
5. Implementar tablero semanal  
6. Implementar validaciones  
7. Implementar APK empleados  
