# Vista: view_turnos_resumen_empleado_mensual_v5

## Descripción
La V5 consolida la información diaria de la V4 en un resumen mensual por empleado.
Es la capa de agregación para liquidación, auditoría y reportes.

## Objetivos
- Obtener una fila por empleado por mes.
- Exponer totales mensuales de jornal y equivalencias.
- Identificar compensaciones y liquidaciones pendientes.
- Facilitar reportes y dashboards.

## Campos principales
- empleado_id
- nombre
- mes
- jornal_total_mes
- jornal_extra_mes
- jornal_normal_mes
- jornal_feriado_mes
- jornal_especial_mes
- dias_trabajados
- dias_descanso
- dias_licencia
- requiere_compensacion_mes
- requiere_liquidacion_mes
- requiere_revision_mes

## Dependencias
- view_turnos_resumen_mensual_v4
- empleados

## Uso
SELECT * FROM view_turnos_resumen_empleado_mensual_v5
WHERE mes = '2026-04-01';
