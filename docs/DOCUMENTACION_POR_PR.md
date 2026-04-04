# Documentación por PR

Todo Pull Request que modifique lógica de negocio, base de datos o interfaz de usuario **debe** incluir la siguiente documentación.

## Checklist obligatorio

### Base de datos / Supabase
- [ ] Se agregó una migración nueva en `supabase/migrations/` siguiendo `MIGRATION_GUIDELINES.md`.
- [ ] La migración es idempotente (uso de `IF NOT EXISTS`, `IF EXISTS`, `ON CONFLICT DO NOTHING`, etc.).
- [ ] Se actualizó `docs/dev/modelos-datos.md` si se crearon o modificaron tablas.
- [ ] Los nuevos objetos tienen RLS habilitado y políticas definidas.

### Flutter
- [ ] Los nuevos modelos tienen `fromJson` / `toJson` y están documentados.
- [ ] Los nuevos providers / servicios siguen la convención de la capa de datos.
- [ ] No se incluyó lógica de negocio dentro de widgets; se delegó a providers o servicios.
- [ ] Se verificó que `flutter analyze` no reporta errores nuevos.

### Documentación
- [ ] Se actualizó el documento de usuario relevante si cambió algún flujo visible.
- [ ] Se actualizó `docs/dev/arquitectura.md` si se agregaron capas o integraciones nuevas.
- [ ] Se creó una entrada en `docs/releases/` si el PR cierra una funcionalidad mayor.

### General
- [ ] El título del PR describe claramente el cambio (ej.: `feat: agregar pantalla de feriados`).
- [ ] El cuerpo del PR describe el problema, la solución y cómo probarlo.
- [ ] No se incluyeron archivos de configuración local (`.env`, `local.properties`, `key.properties`).

## Convenciones de nombre para PRs

| Prefijo | Uso |
|---------|-----|
| `feat:` | Nueva funcionalidad |
| `fix:` | Corrección de bug |
| `chore:` | Cambios de infraestructura / dependencias |
| `docs:` | Solo documentación |
| `refactor:` | Refactorización sin cambio funcional |
| `migration:` | Solo cambios en migraciones SQL |
