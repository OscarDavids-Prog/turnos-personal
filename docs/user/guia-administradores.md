# Guía para Administradores

Manual de uso de la aplicación interna de gestión de turnos para el personal administrativo de Lavasol.

## Acceso

La app interna está disponible para el personal administrativo autorizado. El acceso se realiza con las credenciales de Supabase Auth asignadas por el administrador del sistema.

## Pantalla principal – Tablero semanal

Al ingresar, se muestra el **tablero semanal tipo Excel** con:

- **Filas:** empleados activos.
- **Columnas:** días de la semana (lunes a domingo).
- **Celdas:** turno asignado para cada empleado en cada día.

### Colores de referencia

| Color | Significado |
|-------|-------------|
| Verde | Turno mañana |
| Azul | Turno tarde |
| Naranja | Intermedio |
| Gris | Descanso |
| Rojo | Enfermedad (ENF) |
| Amarillo | Capacitación (CAP) |
| Violeta | Vacaciones (VAC) |
| Negro | Ausencia sin aviso (X) |

## Editar un turno

1. Tocar la celda del empleado y día deseado.
2. Seleccionar el tipo de turno o estado en el panel lateral.
3. Confirmar. La app valida las reglas operativas antes de guardar.

### Reglas de validación

| Sección | Restricción |
|---------|-------------|
| Lavadero | 3 personas activas + 1 intermedio |
| Plancha | 3 turno mañana, 4 turno tarde |
| Prensa | 1 fijo mañana + 1 flexible |
| Secado | 1 mañana + 1 tarde |
| Reparto | 3 todo el día |

Los estados **ENF**, **CAP**, **VAC** y **X** son exclusivos entre sí y entre turnos normales.  
Las combinaciones **L/P** y **PR/DES** son las únicas combinaciones válidas de turno doble.

Si la validación falla, la app muestra un mensaje de error descriptivo y no guarda el cambio.

## Cálculo mensual

En la sección **"Resumen mensual"** se puede ver por empleado:

- Total de días trabajados (mañana / tarde / intermedio).
- Total de ausencias por estado (ENF / CAP / VAC / X).
- Feriados trabajados y su estado (compensado o cobrado).
- Feriados especiales trabajados (1/1, 1/5, 25/12).

## Gestión de feriados

### Feriados normales

1. Ir a **Feriados → Agregar feriado**.
2. Completar: fecha, nombre, tipo (nacional / provincial / comercio).
3. Guardar.

Para registrar que un empleado trabajó un feriado normal:
1. Ir a **Feriados → Trabajados**.
2. Seleccionar empleado, feriado y modalidad: *compensado* o *cobrado*.

### Feriados especiales (1/1, 1/5, 25/12)

Estos días tienen turno único y se pagan aparte. Se registran en **Feriados → Especiales trabajados**.  
La rotación anual del personal asignado a estos días se gestiona en **Feriados → Rotación especial**.

## Navegación semanal

Usar las flechas ← → en el tablero para navegar semana a semana.  
El botón **"Hoy"** regresa a la semana actual.
