Versión 1 — Estado al 5 de abril 2026
🟦 1. Objetivo del módulo
El módulo de turnos tiene como objetivo:

Registrar la actividad diaria real de cada empleado.

Detectar errores operativos automáticamente.

Integrarse con el sistema madre para la emisión de jornales.

Proveer una vista mensual consolidada para auditoría y liquidación.

Representar fielmente la operación real de la empresa (lavadero, plancha, prensa, reparto, etc.).

🟦 2. Tablas creadas
✔ turnos_personal
Registra la actividad diaria del empleado.

Campos principales:

empleado_id

fecha

tipo_turno (mañana, tarde, mixto, partido, libre, etc.)

estado (normal, franco, enfermo, vacaciones, falta, compensado, etc.)

observacion

area (lavadero, plancha, toallas, reparto, etc.)

subturno (normal, intermedio, mañana, tarde, partido, único, doble, medio_extra)

✔ empleado_disponibilidad
Disponibilidad semanal del empleado.

✔ especial_rotacion
Rotaciones especiales.

✔ feriados
Catálogo de feriados (normales y especiales).

✔ feriado_trabajado
Registro de feriados trabajados.

✔ feriado_especial_trabajado
Registro de feriados especiales trabajados.

🟦 3. Seguridad (RLS)
Se implementó RLS con:

✔ Admin (app interna)
Acceso total (CRUD)

✔ Empleado (APK)
Solo puede ver sus propios turnos

No puede modificar nada

Puede ver feriados (solo lectura)

✔ Servicios internos
Acceso total vía service_role

🟦 4. Integración con el sistema madre
El sistema madre:

NO decide si un empleado trabajó o no.

NO decide si trabajó un feriado.

NO decide si hizo doble turno o medio turno extra.

Todo eso lo define turnos_personal.

El sistema madre:

Lee la vista mensual consolidada.

Detecta qué días requieren liquidación.

Emite jornales o los deja para sueldo.

🟦 5. Reglas operativas por área (modeladas en el sistema)
⭐ Lavadero
Lunes a sábado → mínimo 3

3 = 2 normales + 1 intermedio

Lunes y miércoles → pueden ser 4

4 = 2 mañana + 2 tarde (sin intermedio)

Domingo → mínimo 2

Domingo con turismo → mínimo 3 (con o sin intermedio)

⭐ Toallas
Normal: 1 mañana + 1 tarde

Con turismo: puede haber un tercero (normal o intermedio)

⭐ Plancha
3 mañana

4 tarde

Lunes a lunes

⭐ Prensa personas
1 mañana

Lunes a sábado

⭐ Prensa guardapolvos
1 mañana

Puede apoyar lavadero o plancha

⭐ Desmanche
Normalmente lunes y jueves mañana

Puede apoyar prensa guardapolvos, lavadero o plancha

⭐ Reparto
3 personas

2 → turno partido

1 → turno único mañana (sanitarios)

🟦 6. Lógica de turnos y subturnos
tipo_turno
Define la franja horaria:

mañana

tarde

mixto

partido

libre

subturno
Define la modalidad:

normal

intermedio

mañana

tarde

partido

único

doble

medio_extra

Esto permite modelar:

dobles turnos

medios turnos extra

intermedios

partidos

únicos

validación de mínimos

validación de sobreasignación

🟦 7. Lógica de descanso
El descanso:

NO es fijo

NO sigue un ciclo 6/1 rígido

Se mueve según necesidad operativa

Se carga manualmente en turnos_personal

Si no hay turno y no hay descanso → falta

Si trabaja 7 días seguidos → semana desbalanceada

🟦 8. Vista mensual consolidada
view_turnos_resumen_mensual

Genera una fila por empleado por día, con:

✔ Datos del turno
tipo_turno

estado

area

subturno

✔ Cálculos
turno_realizado

horas_normales

horas_extra

turnos_equivalentes

✔ Feriados
es_feriado

es_especial

feriado_id

feriado_trabajado_no_registrado

feriado_especial_no_registrado

✔ Validaciones operativas
descanso_no_asignado

dia_trabajado_sin_turno

doble_turno_no_registrado

medio_turno_extra_no_registrado

semana_desbalanceada

mínimos por área

sobreasignación

polivalencia inválida

✔ Integración con jornal
computa_jornal

computa_sueldo

requiere_liquidacion