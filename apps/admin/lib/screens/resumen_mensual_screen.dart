import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/empleado.dart';
import '../providers/empleados_provider.dart';
import '../providers/turnos_provider.dart';
import '../services/turnos_service.dart';

/// Monthly shift summary screen for a selected employee.
class ResumenMensualScreen extends StatefulWidget {
  const ResumenMensualScreen({super.key});

  @override
  State<ResumenMensualScreen> createState() => _ResumenMensualScreenState();
}

class _ResumenMensualScreenState extends State<ResumenMensualScreen> {
  String? _empleadoSeleccionadoId;
  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen Mensual')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectorEmpleado(
              onChanged: (id) => setState(() => _empleadoSeleccionadoId = id),
            ),
            const SizedBox(height: 16),
            _SelectorMes(
              anio: _anio,
              mes: _mes,
              onChanged: (a, m) => setState(() {
                _anio = a;
                _mes = m;
              }),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _empleadoSeleccionadoId == null ? null : _cargar,
              child: const Text('Ver resumen'),
            ),
            const SizedBox(height: 24),
            Consumer<TurnosProvider>(
              builder: (context, provider, _) {
                if (provider.cargando) {
                  return const Center(child: CircularProgressIndicator());
                }
                final resumen = provider.resumen;
                if (resumen == null) return const SizedBox.shrink();
                return _TablaResumen(resumen: resumen);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargar() async {
    if (_empleadoSeleccionadoId == null) return;
    await context.read<TurnosProvider>().cargarResumenMensual(
          _empleadoSeleccionadoId!,
          anio: _anio,
          mes: _mes,
        );
  }
}

class _SelectorEmpleado extends StatelessWidget {
  const _SelectorEmpleado({required this.onChanged});
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<EmpleadosProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Empleado',
            border: OutlineInputBorder(),
          ),
          items: provider.empleados
              .map(
                (e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.nombreCompleto),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SelectorMes extends StatelessWidget {
  const _SelectorMes({
    required this.anio,
    required this.mes,
    required this.onChanged,
  });

  final int anio;
  final int mes;
  final void Function(int anio, int mes) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
            ),
            value: anio,
            items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                .toList(),
            onChanged: (v) => onChanged(v ?? anio, mes),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
            ),
            value: mes,
            items: List.generate(12, (i) => i + 1)
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat('MMMM', 'es').format(DateTime(anio, m))),
                  ),
                )
                .toList(),
            onChanged: (v) => onChanged(anio, v ?? mes),
          ),
        ),
      ],
    );
  }
}

class _TablaResumen extends StatelessWidget {
  const _TablaResumen({required this.resumen});
  final ResumenMensual resumen;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _Fila('Mañana', resumen.diasManana),
      _Fila('Tarde', resumen.diasTarde),
      _Fila('Intermedio', resumen.diasIntermedio),
      _Fila('Descanso', resumen.diasDescanso),
      _Fila('Enfermedad (ENF)', resumen.diasEnf),
      _Fila('Capacitación (CAP)', resumen.diasCap),
      _Fila('Vacaciones (VAC)', resumen.diasVac),
      _Fila('Ausencia (X)', resumen.diasX),
      _Fila('Compensados', resumen.diasCompensados),
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
      },
      children: [
        _encabezado(context),
        ...rows.map(_filaWidget),
      ],
    );
  }

  TableRow _encabezado(BuildContext context) {
    return TableRow(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      children: const [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Concepto', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child:
              Text('Días', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  TableRow _filaWidget(_Fila fila) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(fila.label),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('${fila.valor}'),
        ),
      ],
    );
  }
}

class _Fila {
  const _Fila(this.label, this.valor);
  final String label;
  final int valor;
}
