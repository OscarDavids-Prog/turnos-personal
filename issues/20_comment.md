## Etapa 2 (Diseño)

### Implementación
Se elige implementar una función SQL parametrizada `fn_turnos_semana(desde date, hasta date)` en lugar de una vista. Esta función documenta el contrato propuesto con las siguientes columnas y uniones:

- **Filtrados de empleados**: solo aquellos con `activo=true`.
- **Filtrado de fechas**: no se realiza filtrado dentro de la vista.
- **Retorno**: la función devuelve una cuadrícula de empleado x día mediante `generate_series`.
- **Left Joins**: 
  - `turnos_personal`
  - `feriados`
  - `feriado_trabajado`
  - `feriado_especial_trabajado`
  - `empleado_disponibilidad` (coincidiendo por `EXTRACT(DOW}`)
  - `empleado_turno_fijo`
- **Validaciones/Sugerencia**: alineadas con `view_turnos_resumen_mensual_v3`.

### Listado de Tareas
- [ ] Implementar SQL de migración.
- [ ] Crear índices si es necesario.
- [ ] Probar rango de muestra `2026-04-06..2026-04-12`.
- [ ] Actualizar documentación y notas de lanzamiento.

**Estado**: Etapa 2 está marcada como lista para implementación mañana.