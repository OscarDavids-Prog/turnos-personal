Documentación técnica — V4 (para tu repo)
Podés pegar esto en:

Código
/docs/turnos/view_turnos_resumen_mensual_v4.md
📘 Vista: view_turnos_resumen_mensual_v4
Descripción general
La V4 es la capa de liquidación del módulo de turnos.
Construye equivalencias de jornal, compensaciones y acumulados semanales/mensuales sobre la base operativa de la V3.

Objetivos
Convertir la operación diaria en valores liquidables.

Unificar reglas laborales reales en una vista única.

Preparar datos para reportes, auditoría y liquidación mensual.

🧩 Dependencias
view_turnos_resumen_mensual_v3

empleados

feriados

turnos_personal

🧮 Cálculo de equivalencias
Reglas por tipo de empleado
Modalidad / Relación	Jornal base	Jornal extra
sueldo / mensual	incluido en sueldo	solo excedente
jornal / jornal	se liquida todo	excedente + base


Equivalencias
Situación	Jornal equivalente	Jornal extra
Día normal	1	0
Feriado trabajado (mensual)	2	1
Feriado trabajado (jornal)	2	2
Feriado especial (mensual)	2.5	1.5
Feriado especial (jornal)	2.5	2.5
Medio turno extra (mensual)	1	0.5
Medio turno extra (jornal)	1.5	1.5
Doble turno (mensual)	2	1
Doble turno (jornal)	2	2
Vacaciones / Enfermo	1	0
Franco / Descanso	0	0


📊 Acumulados
acumulado_semana: suma de jornales por semana (lunes–domingo)

acumulado_mes: suma de jornales del mes

jornal_total_mes: total mensual

jornal_extra_mes: total de excedentes

jornal_normal_mes: días normales

jornal_feriado_mes: feriados trabajados

jornal_especial_mes: feriados especiales trabajados

🚨 Flags
requiere_compensacion

requiere_liquidacion

tipo_equivalencia